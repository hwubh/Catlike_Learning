1##Virtual Texture 的方法总结及可行性报告。

###Virtual Texture定义:
- 因为内存/显存使用，带宽消耗等考虑, 选择不将一张巨大的贴图（集）载入内存/显存 ，而是该贴图（集）进行管理，根据场景加载需要的贴图。（在GPU根据场景中的mesh推断，不同于在CPU通过逻辑管理的Texture streaming)（在这种情况可将Virtual Texture 视为场景中唯一使用的贴图， 单独的mesh不再于单一的材质绑定）。 ---》Texture
- 通过中间索引层（类似于虚拟内存的跳转表），将虚拟地址（Virtual uv）转化为实际坐标（Physical uv）。将mesh与材质/贴图分离，只在材质中保留索引。---》Virtual
- ---》Virtual Texture
![![enter image description here](tflpictures202306tapd_30659243_1687334888_147.png)
](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202306tapd_30659243_1687334888_147.png)%0D%0A.png)
<center>（Virtual uv到 Physical uv的跳转过程）</center>


###常规流程:
- Feedback Rendering(降分辨率渲染场景)（pixel中包含Virtual texture的Page坐标和mip level）-> 
![tapd_30659243_1687334874_187](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/tapd_30659243_1687334874_187.png)
- Analysis（回读屏幕的像素信息，分析知道哪些贴图需要使用） -> 
- Update physical texture（从磁盘加载贴图至内存（物理贴图上）） -> 
- Update Pagemap（更新从虚拟贴图到物理贴图的映射）-> 
- Render（使用virtual uv 经由跳转表 得到physical uv， 在physical texture上采样）
![tapd_30659243_1687334835_446](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/tapd_30659243_1687334835_446.png)

###项目中使用VT的目的：
- 基础：在保留画面质量的情况下，替代传统的terrain splatting方法，减少渲染时间。
- 扩展：1、将场景中非交互式/静态的物体（山，岩石，透贴）一齐烘焙至地形上。
&emsp;&emsp;&emsp;2、将场景中使用的texture都集成至physical texture上，减少切换渲染状态造成的带宽/渲染消耗。

###几种常见的解决平坦地形的VT方案与在项目中使用的可行性分析：
<!-- ####Software Virtual Texture：

1:索引层(Page table)的大小根据Virtual texture的tile数量决定。目前的主流方案会在使用一张32 bit的texture来存储，每个texel上的信息依次为： PageOffsetX, PageOffsetY, Mip-level, debug.
2: physical page 的边缘需要filtering。
3：加载的texture离线生成。
4：可以配合图形API 进行硬件处理。 -->

<!-- 可行性考虑：方法一：将大世界terrain整体烘焙，打包进包体中，按ETC 1/6的压缩比例来算。对于一个chunk（512*512）使用1024*1024 RGB24的方式，需要占据的包体空间是：288MB-》Mip0. 很明显是无法接受的。
            1：包体问题：预先烘焙混合后的地形，至少需要每种生态一张1024*1024的贴图以保证精度，对于混合地形，需要另外针对每个边界区块烘焙一张高度图记录混合情况。
            2：内存问题： -->

####Streaming VT
- 将整个大世界整体离线烘焙，按照一定的大小将大世界（Virtual Texture， VT）分割为一个个Page。使用一张RGB(A) 贴图（Indirection Texture）作为跳转表。Indirection Texture的每个Texel对应VT的一个page，两者在空间上是连续的。同时申请一张 N * M * Page size的physical Texture用于存储加载的Page。
- 在渲染画面之前预先以低精度（1/16、 1/8或更低）渲染场景，用Virtual uv（世界空间坐标）得到对应的VT上的tile，即Indirection Texture的uv。同时根据uv梯度计算出对应的mipmap level，与physical uv offset（physcial page uv 坐标/ physical page size），存入对应的Indirection Texture的Tile的RGB通道中中。 
![![enter image description here](tflpictures202306tapd_30659243_1687335171_649.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202306tapd_30659243_1687335171_649.png).png)
- 若该texel的对应的tile未加载，则向CPU发出指令，从内存/磁盘中将tile加载（绘制）入physical texture上。 绘制时将virtual uv采样indirection texture（因为Indirection Texture与VT是一一对应且在空间上是连续的） 得到 physical uv，采样physical texture 输出颜色值。
####具体实现：
- 1: 将12288 * 12288 的整个大世界分割为 9216张  128 * 128的贴图（Page）， 以双倍精度提前烘焙，以 48 * 48  ETC 的方式压缩（1/6的压缩比），存入包体中。（大概需要270 MB(四层LOD)）.

- 2: 将内存中常驻一张 96 * 96 * 24/36 bit 的 Indirection Texture，每个texel 对应 Virtual Texture的一个Page， 前三个通道分别存储 physical OffsetX, physical OffsetY, VT Mip map level。 以及一张 3*3*128 的physical map 用于储存加载的贴图。
- 3: 在渲染阴影之前预先渲染场景（1/16 精度，因为只渲染地形，精度可以低点），用Virtual uv（世界空间坐标？）得到对应的VT上的tile，即Indirection Texture的uv。同时根据uv梯度计算出对应的mipmap level，与physical uv offset，存入对应的Indirection Texture的Tile中。 若该texel的对应的tile未加载，则向CPU发出指令，从内存/磁盘中将tile加载（绘制）入physical texture上。 绘制时将uv采样indirection texture 得到 physical uv，采样physical texture 输出颜色值。
- 问题：1：占用包体大，2; 精度不足。

####Procedural VT
- 因为整体离线烘焙大世界会导致包体，与Indirection Texture过于膨大（VT page过大会导致精度问题），所以选择在运行时生成地形（并缓存）。

#####1：（BattleField 3）方案：
![![enter image description here](tflpictures202306tapd_30659243_1687335320_375.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202306tapd_30659243_1687335320_375.png).png)
- 1:将因virtual texture过大而膨胀的Indirect Texture分成多个layer，采用Clipmap的方式让高精度的layer只有部分存在.（因为我们项目主要的问题在于包体，针对Indirection Texture的优化方案暂时没有裨益。）
- 2:将地形混合后存入VT中，参照正常的VT管理策略进行管理。

####2： （Far Cry 4）方案： Adaptive VT: 
- 1：将VT分为相同大小的Sector。离相机近的sectors在Indirect Texture上可以获得更大的page（Virtual image, VI），从而在physical map上占据更多的pages。（在Indirection Texture仍然是每个texel对应physical texture上的一个tile，故更大的VI在physical map对应的面积越大）
![<!-- ![20230621104809](httpsraw.githubusercontent.comhwubhPicgoPicsmainimages20230621104809.png) -->
![enter image description here](tflpictures202306tapd_30659243_1687335417_326.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/%3C!--%20!%5B20230621104809%5D(httpsraw.githubusercontent.comhwubhPicgoPicsmainimages20230621104809.png)%20--%3E%0D%0A!%5Benter%20image%20description%20here%5D(tflpictures202306tapd_30659243_1687335417_326.png).png)
- 2：Indrection Texture在空间上不再是连续的，我们无法通过Virtual uv（世界空间坐标）直接推测出其在Indirection Texture上的位置（uv）。需要通过sector 存储的关于Indirection texture的信息（大小，指该VI占据了Indirection Texture的大小，maxTiles）（位置，该VT在Indirection Texture的位置，subTextureIndirectionOffset）得到Virtual image，再找到对应的的physical uv。
![![enter image description here](tflpictures202306tapd_30659243_1687335385_102.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202306tapd_30659243_1687335385_102.png).png)
- 3：VI 随着相机靠近/远离调整VI的大小，当VI放大（Upscale）时直接拷贝旧VI的内容（作为更高Mipmap层级的内容）。本身仅重新生成 Mip0 级的VI，初始生成时每4个（2*2）MIP0 VI 的page指向 Mip 1 的一个page上，防止渲染时找不到指向physical Texture的映射，之后在重新更新MIP0 VI的内容指向physical Texture。缩小（Downscale）时直接复用原VI的高层级mipmap。
![tapd_30659243_1687335504_957](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/tapd_30659243_1687335504_957.png)
##### 对应项目可借鉴之处：
- 虽然我们项目中相机范围内并无太大的远近区别，需要保证精度一致。但开放世界的远近区分可以类比为SLG大世界中高低缩放的。比如当前相机范围内的这块sector，当相机上移时，等同于开放世界中相机正在远离该sector，可以将其原本的VI缩小（downscale），同时需要加载入与其粒度相同的，本在相机之外的sector。反之相机下降，就相当于接近该sector。这种Adaptiv的思想或许有助于之后完善无极缩放时地面的加载策略与效果保证。
![![enter image description here](tflpictures202306tapd_30659243_1687335504_957.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202306tapd_30659243_1687335504_957.png).png)

<center>（这幅图可以看作时开放世界中相机正在远离，或者SLG俯视角时相机正在上升）</center>

###工程实践的补充：
####Texture Filtering：
-  由于虚拟纹理并没有完整加载，所以各种采样过滤在page的边界会有问题
-  1： Bi-linear Filtering：给physical page加上一个像素的border。
-  2： Anisotropic Filtering： shader中实现Anisotropic Filtering的算法。或者利用硬件实现
-  3： Tri-linear Filtering： 在shader中计算mip level,然后两次地址的转换，采样两个物理纹理的page后进行插值。或者生成一个一层的mipmap，然后利用硬件去直接采样。
####（待续）

###生态接入的VT方案(Clipmap)：

####总结流程：（烘培阶段： 1~5； 绘制阶段：6~）
- 1：当大世界中有新的Chunk加载时，记录该Chunk的Rect，在Tasklist添加对应的task。
- 2：根据Lod的数量（N），申请一张（面积）大小为 N* 512 * 512 的physical texture（常驻内存），每个512 *512 的block对应一个lod层。（同时创建一张同等大小的 Temp Texture 用于Blit 操作）。
- 3：更新相机指向与地面的交点pos（屏幕中点），若相机移动超过一定距离，标记该lod需要更新（默认为该lod层绘制范围的1 / 8， 即若该lod的绘制范围为512， 则相机移动距离超过64时需要更新）。 或当大世界中有新的Chunk加载时，若该Chunk与physical texture上的任何一块lod有重叠时，标记该lod需要更新。
- 4：如果存在某个LOD需要更新，若该lod的Rect与某个Chunk有重叠，且上一帧时该lod的Rect未完全包裹该Chunk的话，标记该Chunk需要重新绘制至Physical Texture上。
- 5：计算pos与上一帧的空间位移与对应uv上的位移。将physical texture blit 到 temp Texture上（因为相机的位置发生了移动，temp texture上部分区域不会被绘制到）， 绘制temp Texture未被绘制的部分，将temp Texture blit 回 physical texture上。
![![enter image description here](tflpictures202306tapd_30659243_1687335493_395.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202306tapd_30659243_1687335493_395.png).png)
- 6：计算片元与pos的相对位移，根据uv梯度计算其大致对应的lod层。通过世界坐标与lod值计算对应的physical texture的uv值，采样Physical Texture。
![enter image description here](/tfl/pictures/202306/tapd_30659243_1687335627_370.png)

####具体实现： 
#####1:TerrainVTFeature-》Create(): 
- 生成TerrianVTPass, 该Pass在绘制阴影之前绘制。 WorldToCameraMatrix->使相机垂直大地图向下。 PorjectionMatrix 生成一个1/4的正交投影。
- 生成TerrainVTGenerator 用于绘制地形。尺寸为1024*1024， （physical texture 为 2*2的规格，存储4层lod。？） center size为64？ 申请四张1024* 1024 的TempRT，分别对应Color，Height， Normal， Lightmap。
- 生成VirtualTextureAtlas，规格为2*2。 同样申请四张4096 *4096 的altas RT，分别对应Color，Height， Normal， Lightmap。其中color altas RT 在shader中声明为 “g_TerrainColorVT”
- 生成四张VirtualTextureRT，每张的index对应altas RT上的一个block。每张的uv分别为（0，0）、（0， 0.5）， （0.5，0）、（0.5，0.5）.size为1024. 同时生成四个对应至四个block的viewport
- 在Shader中声明四个变量："g_TerrainVTInfo" = （2，2，4，0）、“g_TerrainVTSize” = （64，512，0，0）、“g_TerrainVTCenter” = （0，0，0，1）、“g_TerrainRootPos” = （0，0，0）

#####2：TerrainVTPass.Setup()?： 
- 初始化“_listInfo"
- Vector4 "_lodInfo"(记录physical texture 上各个block（lod层） 的世界位置（xyz）与大小（w）. 0123分别为左上，左下，右上，右下。在Shader上声明为“g_TerrainVTLod”，用于)
- “_preLodInfo”。

#####3: TerrainVTPass.Exexute(): 
- update（cam）： 获取相机朝向与大世界的交点“pos”，规整相机位置至blocksize的整数倍上为“tempPos”，blocksize为64，128，256，512（blocksize决定了更新频率）。若lod层数为0，则将tempPos记为TerrainVTGenerator 的“m_CenterPos”。将tempPos 与 blocksize 记在 "_lodinfo"上。而当有新的task存在时，若其与info.pos的blocksize范围有交叠，则该info需要更新。？
- 若TerrrainVTGenerator有需要绘制的task存在，调整相机的视锥体，使之正对terrain，调整正交相机的size，绘制对应lod层级的地形。（不需要绘制的block复制到physical texture上）。 判断条件： 若当前task所对应的mesh的不被当前physical texture上的对应的lod block 所完全包含时，重新绘制。

####缺点:
#####1: 绘制时不同层级之间的过渡（特别是贴花）。生态这里预留了一个用实时噪声混合进行过渡的方案，不过消耗较大，如果要采用类似的方案建议可以预先烘焙一张噪声图即可。
![enter image description here](/tfl/pictures/202306/tapd_30659243_1687335729_771.png)
#####2：每移动1/8时重新烘焙，在平坦地面上跳变较为明显。
![enter image description here](/tfl/pictures/202306/tapd_30659243_1687335747_247.png)
![enter image description here](/tfl/pictures/202306/tapd_30659243_1687335797_566.png)


###项目方案：(待续)

<!-- ###Procedural VT
####方案一：
- 1：考虑到我们SVT占据的包体过大，而效果也不算太好，采用PVT方案在运行时实时生成地形更能符合项目的要求。 目前考虑在渲染将山体，岩石，贴花等不可交互的固定物体都渲染至physical texture上。
- 2：目前考虑到当相机离地表最近时，在地表上占据大约86 * 53大小的矩形，为保证屏幕内地形的精度达标，目前是考虑使用申请一张 3 * 3 * 1280 * 640 的physical texture用于缓存
- physical texture 中一个block -->