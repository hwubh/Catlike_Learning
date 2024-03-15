- 1: ClearRenderTarget => depth / stencil, meaning the default value of depth/stencil textures after being clearing. 
- 2: 想使用SRP Batcher compatibility特性，在HLSL代码中我们必须把每个Properties里的变量放到 CBUFFER 中
- 3: Unity底层会将CBuffer统一放置与动态Uniform缓冲区中，但CBuffer的描述数量或者CBuffers占据的空间超过硬件限制后会造成异常（Shader报错）。可以考虑将一些绘制过程中不会发生变化的Cbuffer放置于静态Uniform中。
- 4: Static batching, combine to a huge VBO, submit the IBO of objects to be drawn.
    Dynamic Batching, combine several objects as an object, submit its VBO and IBO. Need to convert PositionOS(A) to PositionOS(B).
    GPU Instancing, submit a mesh, transform it according to PIA(Per Instanced Attribute).
- 5:  Cbuffer中的变量需要全部用到，不然可能导致使用SRP batcher的物件在OPENGL下无法渲染
- 6: Graphic 接口的指令，如DrawMesh等，在URP中，会等到DrawObjectPass时统一提交，优先级或许高于CommandBuffer的指令。同样，Graphic 接口的SetXX 的函数，优先级也较高。但调用Graphic 需保证一帧内所引用的资源不更改，不于CommandBuffer接口引用的不冲突，不然可能造成问题。
- 7：在Pass的Execute阶段最好不要使用Graphic 与GameObject提供的接口，可能会与CommandBuffer的命令产生时序问题。
- 8：URP pass，先统一调用一次Init， 在调用所有的Setup，最后是所有Execute阶段，Execute是实质的运行阶段（绘制）阶段。
- 9：URP 中，unity内存的cbuffer就占据了7个动态的标识符（非Instancing 的少一个），对于一些maxDescriptorSetUniformBuffersDynamic 为 8 芯片（如Andreno 512以下）的机型，Shader只可以自己定义1~2Cbuffer, 否则（不改动源码的情况下）该shader会被直接抛弃。
- 10：The light map UV are provided via the second texture coordinates channel so we need to use the TEXCOORD1 semantic in Attributes.