SRP Batcher 减少了SetPassCall（如绑定Shader， ）的数量，而不减少DrawCall的数量。（DrawCall的数量取决与Renderer，或者说诸如“DrawIndexedPrimitive”等渲染指令的数量）
![v2-1822f71c9da7ff0713642d91a3274be9_1440w](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-1822f71c9da7ff0713642d91a3274be9_1440w.webp)
左侧传统的Batch划分是使用material为基准，默认每个material使用的均是不同的Shader（Variant），拥有不同的渲染状态。
![v2-42116e2128c272ec928a7e9f19dd0d4f_r-1](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-42116e2128c272ec928a7e9f19dd0d4f_r-1.jpg)
而Unity底层则将使用相同Shader Variant的Renderer（ObjectData）合批，保证他们的渲染状态相同。然后将这些物件的Per Object Buffer 合并提交至GPU。同时改shader变体对应的各种材质（PerMaterial）也会缓存在GPU中，只有当material更新时，才会从CPU传递新数据以更新。渲染时bind对应的material cbuffer和PerObjectLrageBuffer中选择合适的小buffer（PerDraw），然后调用图形API（Drawcall）进行绘制。

参考资料： https://zhuanlan.zhihu.com/p/137455866
https://zhuanlan.zhihu.com/p/378781638
![v2-f8faa91354ba3bd432b450f108025e48_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-f8faa91354ba3bd432b450f108025e48_r.jpg)