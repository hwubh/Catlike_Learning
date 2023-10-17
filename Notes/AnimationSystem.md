## Character Animation
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

## Skinned Animation
  ### First: Skeletons
  - Def: A *skeleton* is comprised of a hierarchy of **rigid pieces** known as *joints*. (Sometimes we also call *joints* as *bones*, but seriously, *bones* are the empty spaces between *joins*)
    ![20231009153709](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231009153709.png)
  - Structure: 
      1: Hierarchy. For N joints, each joint assigned an index (from 0~N-1). Each joint (except for *Root*) has the index of its only one parent (joint).
      ![20231009154233](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231009154233.png)
      2: Order. Represented by a small top-level data structure as an array. Each child joint is placed after its parent in the array.
      3: Joint Info. *Name*(string or 32bit string id). *Index*( of parent). *Inverse bind pose transform* 
      ![20231011175232](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231011175232.png)
  ### Second: Poses
  - Def: *Pose* (of the skeleton) directly controls the vertices of the mesh, represented as the ser of all of its joints' poses.
         *Pose* (of a Joint) is defined as the joint's position, orientation and scale, represeted as a 4\*4 or 4\*3 matrix or SRT( scale, quaternion rotation and vector translation)
  - *Bind Pose*: aka *reference pose* or *rest pose* or *T-Pose*. The pose the mesh would be rendered if it's not a skinned mesh(No skeleton).
                 ![20231011212452](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231011212452.png)
  - Local Poses: def: Parent-relative pose, usually stored in SRT format. (child joint moves when its parent moves). 
                      Mathematically, Joint pose can be represented as an affine transform.
                      (P stands for affine, T: 3\*1 Vector translation, S: 3\*3 diagonal scale matrix, R 3\*3 rotation matrix. j ranges from 0 to N-1) ()
                      ![20231012113258](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231012113258.png)
    - f    
