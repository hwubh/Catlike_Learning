- 1：Unity内存：运行时的内存占用情况：Mono堆内存，通过mono虚拟机分配，多为程序逻辑使用（如通过System命名空间中的接口分配的）；Native堆内存，通过Unity的C++层分配，多为资源（如通过UnityEngine命名空间中的接口分配的）![20240617010250](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240617010250.png) https://wetest.qq.com/labs/150 https://zhuanlan.zhihu.com/p/381859536
  - （托管内存）Mono内存管理：C#代码所占用的内存又称为mono内存，在Unity项目中托管堆内存是由Mono分配和管理。
    - 已用内存与堆内存：堆内存指的是mono向操作系统申请的内存，已用内存指的是mono实际需要使用的内存，两者的差值就是mono的空闲内存。![20240617100055](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240617100055.png)
    - GC:从已用内存中找出那些不再需要使用的内存，并进行释放。1.停止所有需要mono内存分配的线程。2.遍历所有已用内存，找到那些不再需要使用的内存，并进行标记。3.释放被标记的内存到空闲内存。4.重新开始被停止的线程。 
         因为释放的内存回到的是空闲内存，因此mono堆内存只增不减。（IL2CPP中，如果一个Block连续6次GC都没有被访问到，这块内存会被返回给系统）
         因为使用 Boehm GC 算法，所以是非分代的（遍历整个堆），也是非压缩的（不会为内存中的对象重新分配内存地址来消除对象之间的间隙）
  - Native内存管理：资源卸载是主动触发的（例：Resources.UnloadUnusedAssets()），包含场景、资源（assets，比如纹理、网格）、图形API、图形驱动、子系统、插件缓存以及其他的内存分配，无法直接访问与修改，只能通过c#接口来间接访问与操作。
    - 静态加载： Editor 的 Inspector 中直接设置
    - 动态加载：运行时加载资源到内存然后通过代码设置资源。有三种方式，**Resources**，**AssetBundle**， **Addressables**
      - Resouces: Resources 的方法全为静态方法, 对 Resources 文件夹中的资源进行动态加载和卸载。(包体问题)
      - AssetBundle：解决了资源的打包更新问题（可以打分包）
      - Addressables： package，
  - 非托管内存：C# 的方式访问原生内存来微调（fine-tune）内存分配，如通过 Unity.Collections 域名空间下的数据结构，如 NativeArray分配。（ ESC 下的作业系统（Job system）和 Burst，则必须使用 C# 非托管内存）

- 2：Lua：https://blog.csdn.net/qq_14914623/article/details/89513031 https://blog.csdn.net/haihsl123456789/article/details/54017522/
  - 与c#的通信过程：C# Call Lua :由C#文件先调用Lua解析器底层dll库（由C语言编写），再由dll文件执行相应的Lua文件；
                   Lua Call C# : Wrap方式:首先生成C#源文件所对应的Wrap文件，由Lua文件调用Wrap文件，再由Wrap文件调用C#文件；反射方式（系统，第三方api）
  - 通信原理：
    - 通过虚拟栈实现：C# Call Lua:由C#先将数据放入栈中，由lua去栈中获取数据，然后返回数据对应的值到栈顶，再由栈顶返回至C#。
             Lua Call C#:先生成C#源文件所对应的Wrap文件或者编写C#源文件所对应的c模块，然后将源文件内容通过Wrap文件或者C模块注册到Lua解释器中，然后由Lua去调用这个模块的函数。
    - 从内存方面解释：C# Call Lua：C#把请求或数据放在栈顶，然后lua从栈顶取出该数据，在lua中做出相应处理（查询，改变），然后把处理结果放回栈顶，最后C#再从栈顶取出lua处理完的数据，完成交互。 
    - 具体类型传参：简单的值类型(int, float) > 次严重(bool string 各种object) > 严重类(Vector3/Quaternion等unity值类型，数组)
                   简单的值类型可以通过C API传递；
                   bool string：涉及到c和c#的交互性能消耗（需要类型转换）
                   object：传递到Lua的只是C#对象的一个索引。用这个id（索引）表示c#的对象，在c#中通过dictionary来对应id和object。同时因为有了这个dictionary的引用，也保证了c#的object在lua有引用的情况下不会被垃圾回收掉。 
                   Vector3/Quaternion：需要重构
                   数组：转化为lua table， 逐个写入
  - talbe: 一种数据结构,用来帮助我们创建不同的数据类型(如数组，字典)；包含两部分：数组Array，Hash部分
           数字 key 一般放在数组段中，当数字 key 过于离散的时候，部分较大的数字 key 会被移到 hash段中去。这个分割线是以数组段的利用率不低于 50% 为准。 0 和 负数做 key 时是肯定放在 hash 段中的。 
           https://zhuanlan.zhihu.com/p/97830462
  - 内存泄露：1. 本应该local 的变量进入global空间或者module空间了(忘记写local)
             2. c/c++部分调用的lua_ref是否有正常lua_unref释放？ 通过debug.getregistry()可以查到这些ref.
    - 可以通过weak table来监测所有的资源，将所有的资源都加载入weak table中，给table添加__mode元方法，如果这个元方法的值包含了字符串”k”，就代表这个table的key都是弱引用的。一旦其他地方对于key值的引用取消了（设置为nil），那么，这个table里的这个字段也会被删除。若字段还在table中，说明该资源还未被释放。
  - Xlua: https://www.huwenqiang.cn/articles/2023/08/10/1691646605632.html