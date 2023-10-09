- ## Character Animation
  1: Cel Animation (Hand-Drawn): a sequence of still full-screen images of an illusion of motion in a static background.  ----> in electronic equivalent: **sprite animation**, a sequence of sprite pictures( bitmaps...) 
  ![20230829213644](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20230829213644.png) 
  if it repeated indefinitely based on this sequence, it becomes an animation called "Run cycle" --> **Looping Animation**. 

  2: Rigid Hierarchical Animation: a collection of rigid pieces. The rigid pieces are constrained to one another (upper pieces) in a hierarchical fashion, moving along the joints of pieces.
  Characters are divided into parts: pelvis, torso, upper/ lower arms, upper/ lower legs, hands, feet and head
  ![20230829215219](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20230829215219.png) 
   - Pros : 1: Move naturally like mammals.
   - Cons : 1: "Cracking" at the joints. 
  ![20230829220004](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20230829220004.png)
  - Conclusion: works well for robots and machinery since they are contructed of Rigid parts

  3: Per-Vertex Animation and Morph Targets: natural-looking motion as it the mesh is deformed.
  Per-Vertex Animation : the Vertices of the mesh is being moved at runtime according to motion data. (limited in tessellation shader)
  - applciation: *Morph Target Animation* in facial animation, give full control over **every** vertices.

  4: Skinned Animation
  - pro: more efficient performance and memory.
  - Definition: 1: A *skeleton* contructed from rigid "bounds"
                2: A smooth continuous triangle mesh called *Skin*
                3: *Skin* is bound to the joints of the *skeleton*, whose(skin) vertices track the movement of the joints.
  - Contrast with "Per Vertex": single joint is magnified into the motions of many vertices. In this case, the motions of a relatively large number of vetices are contrained to relatively snall number of skeletal joints.

- ## Skinned Animation
  ### First: Skeletons
  - Def: A *skeleton* is comprised of a hierarchy of **rigid pieces** known as *joints*. (Sometimes we also call *joints* as *bones*, but seriously, *bones* are the empty spaces between *joins*)
    ![20231009153709](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231009153709.png)
  - Structure: Hierarchy. For N joints, each joint assigned an index (from 0~N-1). Each joint (except for *Root*) has the index of its only one parent (joint).
    ![20231009154233](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231009154233.png)
  - 