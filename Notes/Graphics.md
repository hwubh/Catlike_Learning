- 1：#Normal #transform #Object_Space #World_Space Stop Using Normal Matrix: https://lxjk.github.io/2017/10/01/Stop-Using-Normal-Matrix.html
    *Tips* :![20240213203944](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240213203944.png) The "M" should be "M<sup>'</sup>"

- 2：Texture Compression： https://zhuanlan.zhihu.com/p/634020434; https://zhuanlan.zhihu.com/p/237940807
  - ETC: 人眼对亮度而不是色度更敏感这一事实。 因此，每个子块中仅存储一种基色 (ETC1/ETC2 由两个子块组成) ，但亮度信息是按每个纹素存储的。子块由1个基本颜色值和4个修饰值可以确定出4种新的颜色值。
    - 2个分块*16bit: 存储1个RGB基色（12bit）, 1bit “diff”， 3bit 修饰位； 16个2位选择器，从四个颜色中选出一个。
  - DXTC：https://en.wikipedia.org/wiki/S3_Texture_Compression
    - DXT1: 用于RGB或只有1bit Alpha的贴图 
      - 4*4*64bit 为一个单位，前32bit存贮颜色的两个极端值(c0,c1)，后32bit分为4*4的lookup page，每个page对应一个pixel和2bit状态符（0:c0; 1: c1; 2:c2(插值的颜色)；3：c3（插值的颜色或transparent, if c0 <= c1））
    - DXT2/3：在DXT1的基础上多出64bit来描述alpha信息，每个pixel的alpha 4bit存储
      - DXT2：color: Premultiplied by alpha
      - DXT3：独立
    - DXT4/5: 在DXT1的基础上多出64bit来描述alpha信息，alpha 以类似color的方式存贮，64bit 包含2个4bit 极端值，16个3bit 状态符。
      - if c0> c1, c2~7 插值； if c0 <= c1, c2~5插值，c6=0, c7=255
  - PVRTC:
    - 不同于DXT和ETC这类基于块的算法，而将整张纹理分为了高频信号和低频信号，低频信号由两张低分辨率的图像A和B表示，这两张图在两个维度上都缩小了4倍，高频信号则是全分辨率但低精度的调制图像M，M记录了每个像素混合的权重。要解码时，A和B图像经过双线性插值（bilinearly）宽高放大4倍，然后与M图上的权重进行混合。
  - ASTC: https://zhuanlan.zhihu.com/p/158740249
    - 每块固定使用128bit，块size：4*4~12*12

- 3：Color Space：https://zhuanlan.zhihu.com/p/548826041 ; https://zhuanlan.zhihu.com/p/66558476 ; https://zhuanlan.zhihu.com/p/609569101
  ![20240610133007](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240610133007.png)
  - Gamma：2.2，屏幕输出时会将颜色变换到Gamma2.2空间中：$l = u^2.2, (l,u \in (0,1))$
  - Gamma矫正：$\frac 1 {2.2}$, 在屏幕输出前转到Gamma0.45，使屏幕最终输出转为Gamma1.0：$u_0 = u_i^{\frac{1}{2.2}}$
  - sRBG: Gamma0.45 Color Space
    - Why: <!-- 1: 存储时进行Gamma矫正；2： -->人眼对暗部更敏感，用更大的数据范围来存暗色，用较小的数据范围来存亮色。（下注）
           - Physically Linear（物理）: 以物理光子数量描述的线性数值空间 
             Perceptually Linear(感知): 以光子进入人眼产生的感知亮度描述的线性数值空间![v2-c3b18b218328d622be8a647b41b9c523_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-c3b18b218328d622be8a647b41b9c523_r.png)
             二者为幂律关系：Vphysically = （Vperceptual）^ gamma
             如果（相机/贴图）用**物理亮度**来记录**感知亮度**，则会有**精度**问题：当感知亮度为0.5时，对应的物理亮度只占据$\frac{1}{4}$的记录空间。用物理空间的亮度值来做为图像texel值的话，会使得保存或描述暗部颜色的bit位数不足，而人眼恰好善长分辨暗的颜色，这会让很多暗的颜色丢失。![v2-943fd8197c308e924e4cbc954f260741_720w](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-943fd8197c308e924e4cbc954f260741_720w.webp)
             因此，通常（相机/贴图）实际记录的是感知亮度。将接收的的物理亮度转化为感知亮度的过程称为**gamma encode**或**Image File gamma**。 将记录的感知亮度转化为物理亮度并发射称为**gamma decode**或**display gamma**。将前两者的乘积（多为*1*），称为**System gamma**。
    - Shader中的处理： 实际运算需现将**感知亮度**（sRGB贴图中的texel值）通过^2.2(**Remove Gamma Correction**)转换成**物理亮度**再实际进行。计算结束后需将结果再通过^0.45(**Gamma Correction**)转化为**感知亮度**。
    - 贴图：一般Diffuse（albedo）为sRBG, 而specular maps、normal maps，light maps，一些HDR格式的图片为线形物理空间（物理亮度）的贴图，以节省转换。
  - Unity：如果选择了Gamma，那Unity不会对输入和输出做任何处理，换句话说，Remove Gamma Correction 、Gamma Correction都不会发生，除非你自己手动实现；而Linear则对Shaderlab中的*颜色*输入，有[Gamma]前缀的Property变量（如*金属度*）以及在*sRGB Texture*采样前进行Remove Gamma Correction。
  - Gamma空间：使用非sRGB diffuse图时可以节省一步Remove Gamma Correction运算。
  - Linear空间：使用sRGB diffuse时美术查看效果方便，shader中可以不用写Remove Gamma Correction。但Remove Gamma Correction必不可少。
             

              