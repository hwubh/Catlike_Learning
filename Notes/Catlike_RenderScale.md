- 1: Variable Resolution: 出于各种因素（画面效果，渲染压力，机型适配等），我们希望在保持应用现实的分辨率不变的情况下，能够动态的调整相机渲染的buffer的尺寸。
  - 1.1: Buffer Settings：限制scale值在0.1~2之间，过大的尺寸在用双线性插值下采样时并不能改善画面质量，反而因为抛弃过多的像素恶化画面表现。
  - 1.2：Scaled Rendering：根据传入的scale值调整CameraRenderer的buffer的尺寸（不包含Scene 相机）。检测是否需要rescale buffer size。
  - 1.3：Buffer Size：使用Vector2Int记录调整缩放后的buffer尺寸。缩小尺寸优化了性能但恶化了画面表现，反之亦然。另外在上采样时，HDR可能会在插值时导致错误的渲染结果。![20240701231811](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240701231811.png)
  - 1.4：Fragment Screen UV：_ScreenParams 记录的是相机的pixel dimensions，而不是缩放后Buffer的尺寸，需要我们自己定义变量作替代（记录尺寸的倒数，变除法运算为乘法）。![20240701233119](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240701233119.png)
  - 1.5：Scaled Post FX：PostFXStack中使用的buffer也需要跟着缩放。缩放的尺寸也会影响Bloom的效果，缩小时会放大bloom的影响范围，反之亦然。一种排查buffer缩放对bloom的影响的方法是：bloom的缩放次数仍然按相机的pixel dimension计算，保持bloom的缩放次数不变。
  - 1.6:Render Scale per Camera: 运行相机使用URP的Render Scale设置，也运行各个相机采用各自的Scale。

- 2：Rescaling：当render scale 不是1是，在最后绘制到frame buffer时需要把比例重新调整(Rescaling)为1.
  - 2.1:Current Approach: 默认的Rescaling方式可能会造成几个问题：
    - 1：在上下采样时对于HDR 大于1（高频）的情况，往往会造成锯齿问题（走样）。其结果与LDR下有较大的出入。（参考上文提到的情况）
    - 2：颜色矫正发生在上下采样插值之后，这可能导致在色块差异较大的地方，其插值导致的色彩（color banding，a subtle form of posterization in digital images）带在颜色矫正后更明显。![20240702004301](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240702004301.png)
  - 2.2：Rescaling in LDR：上述的两个问题都是因为在HDR下插值所造成的，所以一种解决方式便是在LDR下作Rescaling（插值），即在Color grading 和 tone mapping再作 Rescaling。
  - 2.3：Bicubic Sampling：使用双三线性采样进行上采样以减少走样的问题（块状色块过多）。 ![20240702010842](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240702010842.png)
    P.S.: 双三线性采样: https://zhuanlan.zhihu.com/p/473702631
  - 2.4: Only Bicubic Upscaling: 因为下采样时Bicubic与Bilinear差别不大，我们可以设置说只在上采样时使用Bicubic
