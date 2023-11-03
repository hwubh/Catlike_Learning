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
  - Local Poses: 
    - def: Parent-relative pose, usually stored in SRT format. (child joint moves when its parent moves). 
                      Mathematically, Joint pose can be represented as an affine transform.
                      (P stands for affine, T: 3\*1 Vector translation, S: 3\*3 diagonal scale matrix, R 3\*3 rotation matrix. j ranges from 0 to N-1) ()
                      ![20231012113258](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231012113258.png)
    - Joint Scale: *Case1:* **Uniform** scale value -> benefit from the the mathematics of frustum and collision as the bounding sphere of a    joint never perform as ellipsoid, and also save memory.
                   *Case2:* **Nonuniform** scale value -> represented as a Vector3, allowing 3-dimension transformation.
    - Representation in Memeory: Stored in SRT format.
    ![20231018204130](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231018204130.png)
    <center>(Structure of Joint Pose with Uniform scale )</center>
    ![20231018204635](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231018204635.png)
    <center>(Structure of Joint Pose with Nonuniform scale )</center>
    ![20231018205000](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231018205000.png)
    <center>(Structure of local poses of a skeleton)</center>
    - Usage: Joint Pose used as a change of basis (Transfrom)
      The *Joint Pose Transform of a joint(**j**)* **P<sub> j -> p(j)</sub>** takes Points/Vectors in Child Space to its *Parent Joint(**p(j)**)* Space, and vice versa.
    
  - Global Poses: 
    - def: Joint's pose in *model space* or *world space*
    - Formula: model-space pose of a joint(j -> M) = muliplying all local poses from leaf to root.
      ![20231018211324](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231018211324.png)
      <center>(Model Pose of joint <em>5</em> )</center>
      ![20231018211540](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231018211540.png)
      <center>(General format: <strong>Global Pose</strong> (<em>joint-to-model transform</em>) of any joint <em>j</em>, <em>p(0) = <strong>M</strong></em>)</center>
      ![20231019115748](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231019115748.png)
    - Representation: use 4*4 matrix to store.
      ![20231019141946](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231019141946.png)
  
  ### Third: Clips
  - def: aminations of fine-grained motions, usually short and discontiguous, aka *animation clips* or *animations*. Ther movement of a character may be broken into  thousands of clips, which may only affect part of body or be looped.
  - The Local Timeline: *time index* (t), range from 0 to T(duration of the clip). Unlike film, t in game anition is a **float** and **continuous**
    [20231023114653](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231023114653.png)
    - Pose Interpolation and Continuous Time: Clips only store important pose called *key poses*/ *key frames* at specific times, and the computer calculates poses in between via linear or curve-based interpolation.
    ![20231023115808](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231023115808.png)
    Because frame rate of the game is not a constant( usually dependents on CPU or GPU), and game animations are sometimes *time-scaled*.
    Therefore, **time(t)** in clips is both **continuous** and **scalable**
    - Time Units: time is best measured in units of seconds, but also can be measured in units of frames if duration of a frame is decided. 
    t also should be a float or a integer measures very samll subframe time intervals, as there is sufficint resolution in time measurements for tweenting between frames or scaling animation's playback speed.
    - Frame vs Sample: In industry, *frame* may refer to a *period of time* like 1/30, also could be a *single point in time*(e.g., "at frame 42")
      To clarify, *Sample* is used to stand for a *single point in time*.
                  *Frame* is used to stand for a *period of time*
      ![20231023215726](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231023215726.png)
      <center>(animtion created with 30 frames per second consists 31 <em>samples</em> and 30 <em>frames</em> in one second)</center>
    - Frame, Sample and Looping Clips: for *looped*(play repeatedly) animations, the last sample of it should equals to the first sample.  
        Therefore, the last sample of looped animation is redundant and is ommitted for many game engines.
        Overall, if a clip is non-looping, a N-frame clip has N+1 unique samples and N frames.
                 if a clip is looping, then the last sample is redundant, so an N-frame clip has N unique samples and N frames.
    ![20231023220714](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231023220714.png)
          <center>(Last sample of first clip = the first sample of second clip)</center>
    - Normalized Time(Phase): def: normalized the duration of a clip into 1, called *normalized time* or *phase of the clip*.
      use "nomralized time unit" (*u*, range 0~1) as time unit.
      Normalized time is useful when synchronizing multiple clips that may differ in duration. 
      TODO: A EXAMPLE

  - The Global Timeline:
    - def: The timeline of a character starts when the character first created, whose time index is noted by $\tau$.
      ![20231024173210](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231024173210.png)
    - Time-scaling: aka *playback rate*, denoted by *R*. Used to modify the local timelime of clips when they are mapped onto global timeline.
      ![20231025213317](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231025213317.png)
      <center>(<em>R</em> = 2 makes 5-second(s) clips occupy 2.5s long in global timeline)</center>
    - formula: mapping clips to global timeline. 
      - Global start time $\tau$<sub>start</sub>. 
      - Playback Rate *R*
      - Duration *T*
      - num of times it loops, *N*
      - Local time index *t*
        ![20231025214043](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231025214043.png)
  - Comparison of Local and Global Clocks: 
    - Local Clock: Each clip has its own local clock, playback rate *R* and time index *t*. Pros: Simple
    - Glabol Clock: The character has a global clock, usually measured in seconds. Each clip records the global time it started playing, $\tau$<sub>start</sub>. Pros: Synchronizing animations, multiple characters interactive.

    - Synchronizing Animations with a Local Clock
    if clips played in disparete engine subsystems, there will be a delay between clips of events and result of them.
    ![20231027174211](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231027174211.png)
    <center>(The animation of event and result displays in different frames)</center>
    - Synchronizing Animations with a Global Clock
    A global clock approach helps to alleviate many of these synchronization problems, because the origin of the timeline ($\tau$ = 0) is common across all clips by definition.
     ![20231027175245](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231027175245.png)
  - A Simple Animation Data Format: 
    ![20231027175634](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231027175634.png)
    In C++: ![20231027175846](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231027175846.png) 
    For an AnimationClip, it at least contains a reference to its skeleton and an array of AnimationSamples of which the num is (m_frameCount + 1) if unloop or  m_frameCount if loop. Inside the array, each AnimationSample holds an array of JointPoses, SRT matrices.
  - Continuous Channel Functions:
    The samples of a clips are definitions of continuous fumctions over time. Theoretically, these channel fucntions are *smooth* and *continuous* during local timeline. But in pratice, mnay game engines interpolate *linearly* between samples by using *piecewise linear approaximations*. 
    ![20231030211343](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231030211343.png)
  - Metachannels: 
      def: channels encode some game-specific information that not directly poses the skeletons but need to be synchronized with the animation.
      Types: 
      - *event triggers*: for channels that contains *event triggers* at time indices. When local time index pass one of these triggers, a corresponding *event* is sent to the game engine. For example, play a footstep sound a "dust" particle effect when the feet touch the ground.
      ![20231030213653](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231030213653.png)
      <center>(The "<em>Other</em>" channel contains some <em>event triggers</em> in the clip ensure the synchronization of events and animations)</center>
      - Special joints: aka *locators* in Maya. These joints used to encode the position and orientation of virtually any object in the game. For example, tansforms, field of view and other atrributes of camera can be changed by its locators when playing.
      - Ohters: Texture coordinate scrolling, texture animation, parameters of material, lighting and other kinds of objects.

  - Relationship between Meshes, Skeletons and Clips
    - UML Diagram:
    ![20231031210732](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231031210732.png)
    The above UML diagram reflects the relations between classes via *cardinality* and *direction*. As to this pic., the *cardinality* as 1 represents a single instance of the class, while the asterisk indicates many instance.
    *Examples: in this diagram, we say AnimationClip has directed association pointing to Skeleton, meaning that each clips has a reference to a skeleton, while a skeleton can be referenced by several AnimationClips, but for both of them, they can be alive without each other. While the skeleton has a directed composition pointing to SkeletonJoint, meaning that each skeleton has several SkeletonJoints, and each skeletonJoint should be alive under one specific skeletons. Both of them cannot be alive without each other.*
    - Animation Retargeting:
      Usually, an animation is only compatible with a kind of skeleton. However *animation retargeting* allows us to make animation target to other skeletons.
      - Remapping Joint index: if two skeletons are morphologicall identical, just remapping joint indices works.
      - **Retarget pose**: At Naughty Dog, the animator define a special pose as the *retarget pose*. This pose captures differences between the bind poses of the source and target skeleton, and adjust source poses to make them work more naturrally in target skeleton. (TODO)
      -  “Feature Points Based Facial Animation Retargeting” by Ludovic Dutreve et al(TODO)
      -  “Real-time Motion Retargeting to Highly Varied User-Created Morphologies” by Chris Hecker et al. (TODO)
  ### Fourth: Skinning nad Matrix Palette Generation
  - Skinning: The process of attaching the vertices of a 3D mesh to a posed skeleton.
  
  - Per-Vertex Skinning Information
    - Skinned mesh: a mesh attached to skeleton by means of its vertices, whoese vertices are bound to one or more joints and track the joints to a *weighted avergae* position. 
      And for every vertex of skinned mesh, it has following additional information
      - 1: the index or indices of the joint(s) to which it is bound,
      - 2: for each joint, a *weighting factor* decide the influence that joint have on the final vertex position. 
        (for each vertex, joint weights of it sum to **one**)
      ![20231102164251](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231102164251.png)
        <center>(Structure of a SkinnedVertex, since joints weights sum to one, last weight omitted)</center>
    - The Mathematics of Skinning 
      - **Skinning Matirx**: a matrix transforms the vertices from bind pose to current pose (in model space). not a change of basis transfrom.
      - One-Jointed Skeleton
        Denotion: 
          - 1: The Model Space(*M*)
          - 2: The Joint(Local) Space (*J*)
          - 3: The Joint's coordinate axes in bind pose (*B*)
          - 4: The Joint's coordinat axes in cureent pose (*C*)
          - 5: The position of vertices in bind pose in model space (**v**<sup>B</sup><sub>M</sub>)
          - 6: The position of vertices in current pose in model space (**v**<sup>C</sup><sub>M</sub>)
          - 7: The position of vertices in joint(local) spcae (**v**<sub>J</sub>)
          - 8: The matrix transform from Model space to Joint space axes in bind Pose(B<sub>J->M</sub>)
          - 9: The matrix transform from Model space to Joint space axes in current Pose(C<sub>J->M</sub>)
          - 10: The skinning matrix of vertices (K<sub>J</sub>)
        Formula: As **v**<sub>J</sub> is constant, then
          - 1: **v**<sub>J</sub> = **v**<sup>B</sup><sub>M</sub> * B<sub>M->J</sub> = **v**<sup>C</sup><sub>M</sub> * C<sub>M->J</sub>
          - 2: **v**<sup>C</sup><sub>M</sub> = **v**<sub>J</sub> * C<sub>J->M</sub>
                                             = **v**<sup>B</sup><sub>M</sub> * B<sub>M->J</sub> * C<sub>J->M</sub>
                                             = **v**<sup>B</sup><sub>M</sub> * (B<sub>J->M</sub>)<sup>-1</sup> * C<sub>J->M</sub>
                                             =  **v**<sup>B</sup><sub>M</sub> * K<sub>J</sub>
          - 3: K<sub>J</sub> = (B<sub>J->M</sub>)<sup>-1</sup> * C<sub>J->M</sub>
      - Multijointed Skeletons:
        **Matrix Pallette**: an array of skinning matrices K<sub>j</sub>, one for each joint *j*. Used as a look-up table for rendering engine.
        In practice, Animation engines will cache (B<sub>J->M</sub>)<sup>-1</sup>, as it is a constant, and calculate local poses C<sub>J->p(J)</sub> and global poses C<sub>J->M</sub>. And then it can achieve the skinning matrix K<sub>J</sub>.
      - Incorporating the Model-to-World Transform
         Sometimes some engines will premultiply the pallette of skinning matrices by the object's model-to-world transform to save one matrix multiply afterwards.
         However, if we are going to use *animation instancing*, a technique used to apply an animation to multiple characters in the same time, it is better to keep the model-to-world matrix from matrix palette.
      - Skinning a Vertex to Multiple joints 
        If a vertex is skinning to more than one joint, the final position of it is a weighted average of the resulting positions assuming it is skinned to each joint individually. It obeys two formulas.
        - First, the sum of weighted averages of N quantities is **One**
          ![20231103200109](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231103200109.png)
        - Second, for a vertex skinned to N joints with indices j<sub>0</sub> through j<sub>N-1</sub>> and weight $\omega$<sub>0</sub> through $\omega$<sub>N-1</sub>. We have K<sub>j<sub>i</sub></sub> as the skinning matrix for the joint j<sub>j</sub>.
          ![20231103201101](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231103201101.png) 