- 1： Unlit Particles：
  - 1.1：Particle System：
         P.S.: VFX graph 是适用于URP/HDRP的基于computer-shader的系统，多用于大规模/复杂的特效系统；而particle system更适用于一些简单的特效。
  - 1.2：基于unlit创建“Custom RP/Particles/Unlit”，创建对应“particle unlit”材质用于粒子系统。（zwrite off）（GPU instancing不生效，因为粒子是系统的mesh是随机生成（procedural drawing）的）
  - 1.3：Vertex Colors：添加vertex color给材质，通过随机生成vertex color来赋给不同粒子不同的颜色。但需要注意的是，当存在不同颜色粒子时，需要根据深度进行排序，然后渲染，以得到正确的效果。
  - 1.4: Flipbooks: def：Billboard particles 通过循环不同的base map实现动画的效果。需要再“Texture Sheet Animation”设置。
  - 1.5：Flipbook Blending：因为flipbook particles在cycle下循环的频率很低，会有很明显的割裂感。所以可以通过给vertex添加UV coordinates 和 an animation blend factor两个通道，在切换不同的base map时进行过度（animation blend）。![20240626153114](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626153114.png)![20240626154620](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626154620.png)

- 2：Fading Near Camera：为了防止单个粒子出现穿越相机突然消失的情况，我们可以通过Renderer / Max Particle Size 限制粒子所占据的像素数量。也可以根据深度使之靠近相机时逐渐消失（fade）。
  - 2.1：Fragment Data：创建Fragment hlsl和Fragment struct。
  - 2.2：Fragment Depth：在Fragment struct添加透视相机中图元在屏幕空间下的深度。
  - 2.3：Orthographic Depth：添加对于正交相机的支持。（从screen-space position vector的Z值是等同于NDC空间下的深度值，介于0~1，我们需要把深度值变换到相机空间中）![20240626231302](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626231302.png)
  - 2.4：Distance-Based Fading：添加transition Fade的$y = 0$点和范围（Near Fade Distance，Near Fade Range）为Shader Property![20240626234316](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626234316.png) 当深度差越小时，减小alpha值。

- 3：Soft Particles：为避免billboard 粒子与实体物体相交时产生的硬过渡的渲染错误，soft particle 采样depth buffer，计算二者的深度差来控制交界处过渡效果。
  - 3.1：Separate Depth Buffer：在管线中分离color attachmetn和 depth attachment
  - 3.2：Copying Depth：因为depth buffer（RT）不能同时读写，我们需要将depth buffer 拷贝到一张 depth texture（_CameraDepthTexture ）上。 P.S.: 个人理解：其实如果半透阶段渲染粒子不涉及depth buffer的写入的话，应该是可以直接用于读取的。不过对于一些比较旧图形API（DX9, OopenGL）上直接读取depth buffer可能也会有兼容性问题。另外就是，如果不考虑移动端一些比较旧的（不支持OpenGLES 3.0以上的）芯片的话，可以采用MRT在绘制半透时同时渲染depth texture。
  - 3.3：Copying Depth Without Post FX：将copy depth 与 post FX 解耦。
  - 3.4：Reconstructing View-Space Depth：将屏幕空间的片元坐标转到NDC空间中，取xy项作为uv，采样depth texture（point clamp，*SAMPLE_DEPTH_TEXTURE_LOD* macro），返回R通道的值。并需要将深度值变换到相机空间中（OrthographicDepthBufferToLinear for 正交；LinearEyeDepth for 透视）将采样得到的值与uv存入Fragment struct中。
  - 3.5：Optional Depth Texture：构建CameraBufferSettings 集合设计 camera buffer 的配置（HDR， copy Depth, copy Depth Reflections）
  - 3.6：Missing Texture：给depth texture准备一张1*1的backup texture \(*missing*\)。
  - 3.7: Fading Particles Nearby Background: 原理上类似Distance-Based Fading，但深度差算的是depth buffer值与片元的深度。
  - 3.8：No Copy Texture Support：WebGL 2.0 不支持 *CommandBuffer.CopyTexture*， 所以需要在自己写Shader实现。添加一个Pass 只写深度，不写颜色。（ColorMask 0， ZWrite On）![20240627015204](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240627015204.png)
  - 3.9：Gizmos and Depth：make our gizmos depth-aware ![20240627023636](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240627023636.png) 

- 4: Distortion: 基于粒子实现失真*distortion*（如“热扭曲”，“大气折射”之类的）。要实现的需要采样Color attachment
  - 4.1：Color Copy Texture：CameraBufferSettings里添加 copyColor, copyColorReflection。类似copy depth，配置copy color。
  - 4.2：Sampling the Buffer Color：GetBufferColor function that takes a fragment and UV offset as parameters, retuning the sampled color. offset用于扭曲。
  - 4.3：Distortion Vectors：使用贴图存储smoothly transitioning distortion vectors。在shader添加Particle distortion map和_DistortionStrength（uv offset的扭曲程度。随机性由片元的alpha值模拟）
  - 4.4：Distortion Blend：添加系数用于粒子本身颜色与场景颜色的插值混合。
  - 4.5：Fixing Nonstandard Cameras：添加对多相机的支持，从后处理中拆出FinalPass 专门用于copy。