- 1: Combining Cameras：在实践中常常有诸如split-screen multiplayer, rear-view mirrors（后视镜）, a top-down overlay, an in-game camera, and 3D character portraits等需要多个相机同时渲染的情况。
  - 1.1：Split Screen：在场景中放置两个rect.width均为0.5的并列的相机，以实现分屏的效果。在后处理需要用相机的pixelRect设置RenderTarget的Viewport。P.S.:
  对应Tiled-based GPU，当不是full viewport时需要加载绘制对象（RenderBufferLoadAction.Load）。否则RenderBufferLoadAction.DontCare可能会导致渲染错误（有物体跨越了相机的viewport）。（但RenderBufferLoadAction.DontCare本身就可能因为未清除的depth texture等问题导致depth test错误等渲染问题。如果非全屏渲染时最好设置为Clear？？）
  - 1.2: Layering Cameras: 设置overlay camera的天空盒为alpha 0。“final” pass 设置为Blend SrcAlpha（/One） OneMinusSrcAlpha；在drawfinal时，需要设置为“RenderBufferLoadAction.Load” 否则无法得到base camera的texture并参与混合。
  - 1.3：Layered Alpha：Shaderlab中可以分别设置alpha通道与color通道的blend mode。在计算alpha通道我们可以不考虑source的alpha通道，所以设置blend mode 为“Blend [_SrcBlend] [_DstBlend], One OneMinusSrcAlpha”。因为存在要进行alpha clip的实体物体，故通过是否“写深度”来判断是否传入source的alpha值。![20240626014452](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626014452.png)
  - 1.4：Custom Blending：为多层相机配置不同的混合模式。通过脚本挂载在camera下。并将相对应的配置传入后处理堆中作为配置。
  - 1.5：Render Textures：editor下创建Render Texture，作为camera的render target。
  - 1.6：Unity UI：render texture可以通过Raw Image显示出来，使用的是Default-UI shader。为了配置blend mode，我们可以覆写Default-UI shader。
  - 1.7：Post FX Settings Per Camera：各个相机可单独改写作用于该相机的后处理效果

- 2： Rendering Layers：Unity只支持单个场景存在。
  - 2.1：Culling Masks：每个gameobject都有对应的layer。Cameras/Lights 可以通过culling masks限制作用在特定layers的gameobjects。但对于 directional light和未开启“Use Lights Per Object”的spot/point 光源只影响阴影的开关。而开启了“Use Lights Per Object”后，spot/point 光辉还会影响光照计算的开关。![20240626023558](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626023558.png)
  另外，考虑到layers是绑定到gameobject上，而不是renderers上。而且layers 还需要参与到物理系统中。对于lights更推荐使用“Rendering Layer Mask”进行控制。
  - 2.2： Adjusting the Rendering Layer Mask：Rendering Layer Mask默认有32layers，名称可以通过“RenderPipelineAsset.renderingLayerMaskNames”改写(教程说对MeshRenderer生效，但对lights不生效，但在Unity2022中两个都没生效？？)。若要在lights，meshrenderers上覆写Rendering Layer Mask的名称，需要自定义二者的inspector界面，添加一个EditorGUILayout.MaskField与原来的Rendering Layer Mask进行绑定。但又因为SerializedProperty只支持signed integer，而Rendering Layer Mask是uint，故自定义的EditorGUILayout.MaskField只能使用31bit，即layer 32是无法使用（access到）的。
  - 2.3：Sending a Mask to the GPU：把Rendering Layer Mask/EditorGUILayout.MaskField传到GPU侧, 使用“asuint”把改变位模式（bit pattern）（float->uint, 不是转换，raw data相同）。用bitwise-AND检测片元（对应的物体）的renderingLayerMask是否与light的重叠（$\not ={0}$）
  - 2.4:Reinterpreting an Int as a Float: 自定义一个“public static float ReinterpretAsFloat (int value)”，The memory contents of the integer value interpreted as a floating point value。定义一个如下的struct：使结构的两个字段重叠，共享相同的数据![20240626031706](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626031706.png)
  - 2.5：Camera Rendering Layer Mask：为camera添加一个rendering layer mask字段。![20240626032344](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240626032344.png)
  - 2.6：Masking Lights Per Camera：Lighting.SetupLights中检测每个光源的渲染层掩码是否与该光源的掩码重叠。让两个摄像机渲染相同的场景，但是使用不同的灯光，而不必在两者之间进行调整。这也使得在世界原点轻松渲染独立的场景（如人物肖像）而不会受到主要场景的灯光影响。