##自定义阴影贴图：动态/静态物体分离+自适应尺寸优化
###起因：
实时渲染阴影贴图并采样在低端机的消耗过大，考虑参考其他大世界slg手游的阴影方案进行优化。确保所有要求机型上都能实现理想的阴影效果。根据VS4的数据来看，二档下以及三档的机型在阴影的消耗超标。
###方案分析：
####一： Shadow Caching 
	将场景中静态的阴影离线烘培下来，分成多张，多层的较小的贴图。采用流式加载，当进入大世界场景时载入需要的阴影贴图，场景切换时动态地卸载不需要的贴图，加载需要的贴图。
	优点：计算量小，不需要实时计算静态物体的阴影范围。而且因为时离线烘培，可以采用高精度，高计算，高质量的阴影渲染方案。
	缺点：大量贴图需要打包进包体中，占用大量的设备硬盘空间。当场景的光源属性发生变化要重新烘培，而贴图数量随场景中光源的状态的数量呈倍数上升。
#### 二：Fake Shadow
	将一个假的阴影面片与模型结合，在渲染模型时将事先画好的阴影一起画出。
	优点: 不需要实时计算，绘制阴影。阴影外轮廓与角色更贴合。
	缺点： 阴影永远朝向一个方向。无法避免"桥上桥下"（遮挡）问题，无法解决穿帮问题。![tapd_30659243_1670319509_7](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/tapd_30659243_1670319509_7.png) （图中阴影应该时水平方向射来的，阴影确实垂直向下的。）
#### 三：Projector Shadow
	想用一个虚拟相机/projector 渲染场景物体的轮廓图，轮廓内的记为0，轮廓的外的记为1。当渲染物体采样轮廓图，若采样值为0，则为阴影，反之则没有阴影。
	优点：实时渲染阴影，阴影随物体，光源发生变化。 不需要像shadowmap一样存储一张深度图。
	缺点：无法判断遮挡问题。![tapd_30659243_1670320172_75](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/tapd_30659243_1670320172_75.png)
#### 四： Planar Shadow:
	设置平面高度，计算实体物体顶点在平面的投影，生成一个对应的skinnedmesh（或将对应顶点加入渲染流程中），渲染为阴影的颜色。
	优点：实时渲染阴影，阴影随物体，光源发生变化。精度较高，不需要额外的贴图，
	缺点：渲染的顶点翻倍，无法避免遮挡问题。
	![![enter image description here](tflpictures202212tapd_30659243_1670321707_31.png)![enter image description here](tflpictures202212tapd_30659243_1670321714_37.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202212tapd_30659243_1670321707_31.png)!%5Benter%20image%20description%20here%5D(tflpictures202212tapd_30659243_1670321714_37.png).png)
	
#### 五：Shadowmap
Unity默认的实时渲染方案，从光源位置渲染物体的深度信息至一张深度图上。渲染物体时采样比较片元与采样得到的深度，若片元深度大于采样值，则该片元被遮挡，反之则无。
优点：可以解决遮挡问题。
缺点：阴影质量受贴图精度影响（容易产生锯齿），采样消耗大。![![enter image description here](tflpictures202212tapd_30659243_1670322209_26.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202212tapd_30659243_1670322209_26.png).png)（从光源位置渲染的深度图）。

###分析
优化方向：1：绘制阴影：申请贴图，切换渲染对象。
		2：绘制阴影：顶点计算，绘制深度。
		3：绘制物体：阴影采样。
		4：CloseFit：提升阴影贴图利用率。


[^注释摘要]: 优化方案：1：动静态物体分离，缓存静态物体。--- 减少绘制阴影阶段的顶点计算，减少申请，切换贴图的次数。
			2：自适应的阴影尺寸：根据视锥体与裁剪物体包围盒确定阴影贴图的大小，在保证阴影精度的情况下，申请较小的阴影贴图。---减少贴图分配的内存，减少切换渲染对象的消耗。
			3: 分帧渲染动态阴影：将动态的阴影贴图分为四个区域，每帧更新其中一个区域。将动态阴影贴图的更新频率降低至7.5帧/s。
			4：优化着色器的计算
			5：使阴影贴图贴合视锥体。

###具体优化：
- 1： 动静态物体分离，分成一张临时的动态阴影的贴图，一张常驻的绘制静态阴影的贴图： 减少绘制时传输至GPU测的顶点数据，从而减少带宽。
- 2：自适应的阴影范围: 根据视锥体与裁剪物体包围盒确定需要渲染至阴影贴图的范围，提升阴影贴图的像素利用率。在阴影贴图尺寸不变的情况下，尽可能地提升阴影贴图的精度。（或在保证阴影贴图的精度的情况下，尽可能减小阴影贴图的尺寸。）
- 3：在相机达到一定高度时分帧更新阴影贴图：减少每帧的渲染压力与带宽消耗。（暂时未启用）
- 4：优化着色器的计算。（效果可能较小，暂时未启用）
- 5： 使阴影贴图贴合视锥体。（尽可能提升阴影贴图利用率）

			
###动态/静态物体分离: 步骤：


[^注释摘要]: 一： 
``` 
计算大世界相机的视锥体与剪裁物体的包围盒的重叠面积，确定阴影贴图尺寸（宽：高 = 1.21， 符合光源空间中视锥体的长宽比。 宽为256的倍数，以适合unity内部render texture 的对象池）--- 确定的阴影尺寸为：512 * 620， 768 *  930， 1024 * 1240， 1280 * 1549， 1536 * 1859， 1792 * 2169。![enter image description here](/tfl/pictures/202212/tapd_30659243_1670326994_63.png) （默认shadowmap渲染的阴影贴图： 2048 *2048）![enter image description here](/tfl/pictures/202212/tapd_30659243_1670327061_65.png) (视锥体大于物体包围盒时渲染的阴影图： 1240 * 1024) !
	![enter image description here](/tfl/pictures/202212/tapd_30659243_1670327102_58.png) （视锥体小于物体包围盒时渲染的阴影图： 512 * 620）四： 当相机移动时，只申请一张临时Render texture（RT）用于绘制阴影。当相机静止时，申请一张RT并缓存，将静态物体绘制于静态RT上。![enter image description here](/tfl/pictures/202212/tapd_30659243_1670327978_60.png) （缓存的静态物体阴影）	![enter image description here](/tfl/pictures/202212/tapd_30659243_1670328043_24.png) （绘制上动态物体之后的阴影图）
		三:   使用TextureCopy 将静态RT的像素复制到临时RT上，将动态物体绘制上去。
	P.S.: 这里用TextureCopy的消耗与阴影贴图的尺寸呈线性正比。
```


一： 申请一张1280 *1280 的RenderTexture作为静态阴影贴图， 一张1280* 1280的临时RT作为动态阴影贴图，以及一张1* 1 的临时RT作为fallback。 
**!12 /（P.S. 由于URP创建RT的接口默认为Object接口，而非CommandBuffer的接口，不与CommandBuffer指令在一个队列中，无法保证时序。固必须在Execute之前申明RT，防止因为时序问题造成渲染错误，）/! 。**
二： 根据CullingMask 分离动态物体与静态物体，重新进行剔除，分别得到对应的剔除结果
![![enter image description here](tflpictures202309tapd_30659243_1695093534_911.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202309tapd_30659243_1695093534_911.png).png)
三： 针对剔除结果计算对应的视图矩阵与投影矩阵，分别存储将动静对应的矩阵存储在级联第一级与第二级。
![![enter image description here](tflpictures202309tapd_30659243_1695093586_206.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202309tapd_30659243_1695093586_206.png).png)
三： 计算视锥体（平行边）与阴影贴图的夹角，旋转阴影贴图使之与视锥体的平行边平行。
并将阴影贴图旋转180度，使靠近视锥体近平面的物体分配到阴影贴图下方更多的像素。
**	（Unity 原生Shadowmap的渲染范围。StableFit）**
	![20231110115608](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231110115608.png)
**	（CachedShadowmap 贴合视锥体+ 旋转180度后的渲染范围。CloseFit）**
	![20231110115513](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231110115513.png)
四： 计算大世界相机的视锥体与剪裁物体的包围盒的重叠面积, 
![tapd_30659243_1695093641_421](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/tapd_30659243_1695093641_421.png)
**(视锥体大于物体包围盒时渲染的阴影图) **
![![enter image description here](tflpictures202212tapd_30659243_1670327061_65.png) ](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202212tapd_30659243_1670327061_65.png)%20.png)
**（视锥体小于物体包围盒时渲染的阴影图）**
![![enter image description here](tflpictures202212tapd_30659243_1670327102_58.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202212tapd_30659243_1670327102_58.png).png)
***!12 	P.S.: 设置projection matrix时需要注意Unity内部对渲染设置的Projection Matrix有scale和translate变换。!***
五： 绘制静态贴图时：设置一个虚拟相机至光源处，调用context.DrawRenderers接口绘制。绘制在一张长期缓存的render texture上。
      绘制动态贴图时，直接调用context.DrawShadows接口绘制，绘制在一张temporary render texture上
**!12 *P.S.: 同一帧内调用两次context.DrawShadows可能造成绘制内容的错误。而使用context.DrawRenderers 则会忽略MeshRenderer的“Cast Shadows”属性，需要手动配置。所以选择使用DrawRenderers来绘制需要本就需要手动配置的静态物体，使用DrawShadows来绘制动态物体（，自动剔除不cast shadow的物体）。未来使用场景管理来配置动静物体队列后，可考虑抛弃context的绘制接口。*!**
六： 当主相机移动时，清除静态贴图，绘制所有物件（包含动静）到动态贴图上。当主相机静止时，绘制静态物体至静态贴图上，绘制动态物体至动态贴图上。
七： 分别从静态阴影贴图和动态贴图上采样，比较最小值，确实是否在阴影遮蔽内。
（与Unity原生的shadowmap方案兼容，防止非Game camera外的相机阴影渲染错误）

**!12 *P.S.: 但因为使用级联的结构存储数据，修改后的shadow.hlsl无法正常使用级联阴影*!**
（八）： 在英雄展示场景时，始终使用动态阴影贴图单独绘制英雄，保证英雄的效果。而将其他物件绘制在静态阴影贴图上。（主要防止移动时，英雄阴影的精度相对于静止时的精度发生较大的变化）。

（最终效果）： 
（Unity原生效果）

（CustomShadowmap效果）


###尺寸优化原理：
	一：计算出大世界相机视锥体与剪裁物体的AABB包围盒，在光源视口坐标系的坐标。
	二： 计算视锥体与与阴影贴图的夹角 *AngleA*， 视锥体绕视锥体重心旋转 *-AngleA*，使视锥体与阴影贴图平行。再旋转视锥体180度，使离相机近的物体分配更多阴影贴图的像素。
	![![enter image description here](tflpictures202309tapd_30659243_1695094012_995.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202309tapd_30659243_1695094012_995.png).png)
	（静态阴影的渲染范围）
	![![enter image description here](tflpictures202309tapd_30659243_1695094469_580.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/%09!%5Benter%20image%20description%20here%5D(tflpictures202309tapd_30659243_1695094469_580.png).png)
    （动态阴影的渲染范围）
	![20231110115825](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231110115825.png)
	三： 计算视锥体与包围盒在光源视口坐标系的重叠部分，得到重叠矩形的长宽与原点（0，0）坐标.
	（Unity 原生Shadowmap的渲染范围。蓝色部分为浪费的精度，主相机视锥体外的空间）
	![20231110115857](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231110115857.png)
	四：根据二者得到的尺寸申请最小需要的阴影贴图尺寸。根据原点坐标得到从变换矩阵。
	
###分帧渲染：
	一： 设置相机的render target 的RectPixel 为四分之一方格，清除该区域。![![enter image description here](tflpictures202212tapd_30659243_1671681911_30.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202212tapd_30659243_1671681911_30.png).png)
	二： 调整Culling Sphere的中心至方格区域的中心，半径设置为场景物体的AABB包围盒的斜边长（extends）的一半。保证只有方格区域内物体被绘制，避免重复绘制。
	三： 调整相机的render target 的RectPixel 至顺时针方向的下一个四分之一方格。
	
###优化片元着色器的计算：
	一： 将阴影坐标的计算从片元着色器中移至顶点着色器中。![enter image description here](/tfl/pictures/202212/tapd_30659243_1671682426_11.png) 提高整体的运算效率。
	
	### 当前方案的问题: 
- 1: 多缓存了一张阴影贴图在内存中，造成了内存与贴图传输的带宽的上升。
- 2：采用了CloseFit的方式，移动/旋转相机时可能造成阴影抖动。***!12 P.S. 参考文章：https://zhuanlan.zhihu.com/p/398845021!***
- 3： 相机一移动就更新阴影贴图，更新频率过高。
- 4：使用Unity的GetShadowCasterBounds接口得到剔除结果包围盒误差较大。

###涉及的文件的位置：

###未来的一些构想：
- 基于场景管理的大尺寸Cached Shadowmap： 采用类似重返帝国的方式，将较大范围的静态物件都绘制在静态阴影贴图上，相机在一定范围进行移动不需要静态阴影图。
实现思路：在逻辑中维护两个buffer A,B，A Buffer加入一整个Chunk（512 * 512）所有物件的信息，这部分数据提交给Cached Shadowmap Pass中用于绘制静态阴影贴图，只有当相机视锥体超出阴影范围（光源相机视锥体范围）的时候，才会更新 ABuffer的信息，重新绘制静态贴图。 B Buffer 则是将A Buffer 的数据根据主相机进行二次剔除，得到需要实际绘制出的物件，提交给至Draw Object Pass 实际绘制在游戏中，B Buffer则是每帧进行维护的。
（重返帝国的静态阴影图）
![![enter image description here](tflpictures202309tapd_30659243_1695104053_587.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5Benter%20image%20description%20here%5D(tflpictures202309tapd_30659243_1695104053_587.png).png)