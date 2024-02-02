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
  
  ### Animation Blending
  - Def: A technique blending combines two or more *input poses* to produce an *output pose* for the skeleton.
  - Usage: 
    - First: combines two or more animations into a host of new animations without creating them manually.
    - Second: find intermediate pose between two known poses at different points in time, usually used in poses that does not correspond exactly to one of the sampled frames available in the animation data.
  - LERP Blending
    - Def: *linear interpolation*.
    - Formula: $\beta$ called *blend percentage* or *blend factor*, range from 0 to 1.
      ![20231107164631](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231107164631.png) 
      As we are linearly interpolating *joint poses*, the *4\*4 transformation matricses*, which is not pracitcal to interpolate matrices, we do interpolation on each component of the SRT individually.
      - Translation:  LERP: ![20231107165152](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231107165152.png)
      - Quaternion: LERP or SLERP: ![20231107165257](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231107165257.png)
      - Scale: LERP: ![20231107165347](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231107165347.png)
      
      To ensure the result of blending looks biomechanically implausible, we do the linear interpolation on local poses, which means the interpolation can be performed entirely in parallel as these joint's poses are totally indepedent. 
  - Application of LERT Blending
    - Temporal Interpolation:  Because of the variable frame rate, player might see frames 0.9, 1.85, 2.18 that are between the sampled poses.
      For example, there is a clip contains evenly spaced pose samples at times 0, $\delta t$, $2\delta t$, $3\delta t$. To find a pose at time t = $2.18\delta t$, the blending percentage $\beta$ = 0.18, determined by ![20231107171907](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231107171907.png)
      Then we get the result: ![20231107171932](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231107171932.png)
    - Motion Continuity: Cross-Fading
       - To ensure the character's body move smoothly, the continuity should be followed.
         - C0 continuity: the paths are continuous (the position of joints are continuous)
         - C1 continuity: the first derivatives (velocity) of pahts should be continuous. 
         - C2 continuity: the second derivatives of the motion paths (acceleration curves) should be continuous. 
       - Pros: LERP-based animation blending can achieve a reasonably pleasing form of C0 motion continuity, also be approximating C1 continuity.
       - Cons: introduce some unwanted artifacts, such as the dreaded "sliding feet".
    - **Cross-fading**:  When LERP is used in the transitions between clips, it also is called **Cross-fading**. 
      - How: when corss-fade between two animations, we will overlap the timelines of the two clips by some reasonable amount, and the blend clips. Then blend percentage $\beta$ starts at zero at t<sub>start</sub>(start time of cross-fade).  $\beta$ is increased until the time reach the t<sub>end</sub>(end time of cross-fade). The time interval over which the cross-fade occurs is called *blend time* ($\deltat$ <sub>blend</sub> = t<sub>start</sub> - t<sub>end</sub>).
      - Types: 
        - Smooth transition: Clip A and B both play simultaneously as $\beta$ increases from zero to one. (clips must be looping animations, timelines must be synchronized. WHY?)
        ![20231108143541](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231108143541.png) 
        - Frozen transition: The local clock of clip A (fore one) is stopped at the monment clip B starts playing. (For clips that are unrelated and cannot be time-synchronized)
        ![20231108143553](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231108143553.png) 
      - **ease-in/ease-out curve**: the blend factor $\beta$ can be varied following a cubic function of time, such as a one-dimensional Bezier. Such curve is called *ease-out curve* when blending out and *ease-in* when blending in.
      ![20231108145119](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231108145119.png)
      - formula:  $\beta$<sub>start</sub>: the blend factor at the start of the blend interval t<sub>start</sub>.
                  $\beta$<sub>end</sub>: the blend factor at the end of the blend interval t<sub>start</sub>.
                  $\mu$: the *normalized time* between t<sub>start</sub> and t<sub>end</sub>.
                  $\nu$: the *inverse* normalized time, 1 - $\mu$.
                  The Bezier tangents T<sub>start</sub> and T<sub>end</sub> are taken to equal.
                  ![20231108150113](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231108150113.png)
      - Core Poses: As C0 continuity can be achieved without blending  if the last pose pose in former clip matches the first pose in later clip. In practice, the animators often decide a set of *core poses*, each of which plays the first and last pose in a kind of clips to ensure C0 continuity. AND To achieved C1 or higher-order motion continuity, the smooth transition between clips by means of authoring a single smooth animation and then breaking it into two or more clips. (How?)
    - Directional Locomotion: 
      - Pivotal Movement: 
        - Def: Character turn his entire body to change direction and faces in the direction he is moving and pivots about his vertical axis when he turns.
        - How: Play the forward locomotion loop while rotating the entire character about its vertical axis to make it turn. To make it natural when characters is turning, we avoid the character always keep bolt upright and blend three variations on the basic forward walk or run, straight, extrme lelf and extreme right via LERP-blend to ahcieve desired lean angle.
      - Targeted Movement: 
        - Def: Character can keep his face in one direction while walking in any direction.( known as *strafing*)
        - How: the animator authoers three separate looping animation clips- one moving forward, one to left, and one to right, which are called *directional locomotion clips*. With fixing the character direction at 0 degrees, the desired movement direction is decided by the blending of two adjacent movement animations via LERP-based blending. The blend percentage $\beta$ is determined by how close the angle of movement is to the angles of adjacent clips.
        ![20231108162549](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231108162549.png)
        - Cons: The reason that we use semicircle instead of a full circular blend including the backward movement is directly blending the backward movement and left/right movement causes awkward and unnatural movement. There are one possible way to solve:
          - define two hemispherical blends, one for forward motion, and one for the backward, each with strafe animations that have ben crafted to work properly when blended with the corresponding straight run. When passing from one hemisphere to the other, the explicit transition animation is play to make the cahracter adjust its gait and leg crossing appropriately.
    - Complex LERP Blends:
      - Generalized One-Dimensional LERP Blending
        define a new blend parameter $\beta$ lies in any linear range desired with any num of clips positioned at arbitrary points along this range. Pick two adjacent clips to blned, if the clips lies at pont  $\beta$<sub>1</sub> and $\beta$<sub>2</sub>. 
        ![20231113111342](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231113111342.png)
      - Simple Two-Dimensional LERP Blending.
          A 2D blend involves only four animation clips can be seem as two 1D blends. The generalized blend factor *b* becoms a two-dimensional blend factor **b** = [*b*<sub>x</sub> *b*<sub>y</sub>].
          ![20231113172431](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231113172431.png) 
      - Triangular Two-Dimensional LERP Blending
         To perform LERP on any num of animation clips, for each clip, designated by the index *i*, corresponds to a particular blend coordinate **b**<sub>i</sub> = [*b*<sub>ix</sub> *b*<sub>iy</sub>] in our two-dimensional blend space.
         For example, in a triangular blend, we have ![20231113173618](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231113173618.png)
         by assgin barycentric coordinate (1,0,0), (0,1,0), (0,0,1), we can produce the **b**<sub>0</sub>, **b**<sub>1</sub>, **b**<sub>2</sub>, and furthermore find the poses **P**<sub>0</sub> and so on. ? https://codeplea.com/triangular-interpolation
      - Generalized Two-Dimensional LERP Blending
         To blend any num of clips, *Delaunay triangulation* is introduced, which seperates the polygon into a set of triangles and blend together. ![20231113174913](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231113174913.png)

  - Partial=Skeleton Blending
      - Def: a techinque to implement a kind of movement that only move part of the skeleton.
      - How: For each joint, it has its own blend percentage $\beta$<sub>j</sub>. The set of all percentage is called *blend mask* ![20231113175226](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231113175226.png). When perform partial-skeleton clips, the animator create a single animation apart from the full-body animation with the blend mask that define static joints as 0:![20231113175624](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231113175624.png) 
      - Cons: 
        - 1：An abrupt change in the per-joint blend factors cause the moving part appear disconnected from the rest of the body. Solved by gradully changing the blend 
        - 2: The movements of a real human body are never totally independent and looks more "bouncy". Sovled by *additive blending*.

  - Additive Blending
    - Def: *Additive Blending* introduces *difference clip*, aka *additive animation clips*, which encodes the *change* from one pose to anohter pose. For example, we have a running clip called *reference clip*(R) and a running in a tired manner called *source clip*(S), the we have the *difference clip*(D) = S - R, encoding the change to make running characters looks tired. In this case, we can also apply D to other Rs, aka *target clips*(T), to create poses like characters looks tired while walking, jumping and so on.
    - Mathematical Formulation
      As the joint poses is a 4*4 affine transformation matrix, the subtraction of it is multiplication by the inverse matrix.
      For every joint j, we have ![20231114160313](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231114160313.png)
      By adding a D<sub>j</sub> onto T<sub>j</sub>, we have a new additive pose A<sub>j</sub>: ![20231114160423](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231114160423.png)
      - Temporal Interpolation of Difference Clips
        As the game animation are nearly never sampled on integer frame indices. The *temporally interpolate* also applies to difference, but should ensure the difference clips is undefined if S and R are not the same duration. ?
      - Additive Blend Percentage
        we can also apply LERP to achieve A: ![20231114161349](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231114161349.png)
    - Additive Blending vs Partial Skeleton
       Additive Blending: 
       - Pros: Looks more natural and can apply to a wide variety of animations.
       - Cons: May cause over-rotate the joints in skeleton when multiple difference clips are applied simultaneously.![20231115162330](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231115162330.png)
  
    - Applications of Additive Blending
      - Stance Variation: For each desired stance, the animator creates a one-frame difference animation.
    ![20231115162617](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231115162617.png)
      - Locomotion Noise: used to layer randomness, or reactions to distractions, on top of an otherwise entirely repetitive locomotion cycle.![20231115164159](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20231115164159.png)
      - Aim and Look-At
       To permit the character to look around or to aim his weapon. The character is first animated doing some action with his head or weapon facting ahead. The angle of the aim is governed by the additive blend factor of each clip.
       ![20240118132003](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240118132003.png)
    - Overloading the Time Axis
      ??

  - Post Processing
    - def: modify the pose prior to rendering the character, *animation post-processing*
    - Procedural Animations:
      - def: Animations generated at runtime, used in place of or in additon to hand-animated clips.
    - Inverse Kinematics:
      - def: Take the desired global pose of a single joint, *end effector* , as input and calculate the local poses of other joints
      - error minimization: As there might be one solution, many or none at all, Ik works best when the skeleton starts out in a pose that is reasonbly close toe desired target.![20240120014928](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240120014928.png)
      - In a two-joint skeleton, the rotation of these two joints can be represented by a two-dimensional angle vector $\theta$, all possible solution of which forms a two-dimensional space called *configuration space*![20240120014950](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240120014950.png)
    - Rag Dolls
      - def: A collection of physically simulated rigid bodies, usually used in dead bodies. The transforms are calculated by the physical system and pass to the skeletons.

  - Compression Techniques
    - A single joint pose might be composed of ten floating-point channels, three for translation, four for rotation and three for scale.
    - Channel Omission: 
      - Omit scale channels to one or none channels.
      - Omit translation channels on the bones of a humanoid character except for the root, facial joints and sometimes the collar bones.
      - If quaternions are normalized, only need to store three perquat and compute the fourth at runtime.
      - Omit channels whose pose does not change over clips.
    - Quantization:
      - Reduce the size of each channel. If values lie in the range [-1, 1], the exponent of float can be discarded and furthermore, we can only maintain 16 bits of precision.
      - quantizaiton: convert 32bit IEEE float into n bit integer, is a loosy compression method when encoding and decoding.

    - Sampling Frequency and Key Omission
    Animation data tends to be large for 3 reason: The pose of each joint with ten channels of floating-point data.
    A skeleton contains a number of joints. 
    The pose is sampled at hight rate
    - solution: Reduce the sample rate overall
                Omit some of the samples.
  
    - Curve-Based Compression
    Grany (A animation APIs) stores animations as a collection of nth-order, nonuniform, nonrational B-splines, allowing channels with a lot of curvature to be encoded using only a few data points.
    ![20240125210915](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240125210915.png)

    - Wavelet Compression
    apply signal processing theory via a technique known as wavelet compression. An animation curee is decomposed into a sum of orthonormal wavelets.

    - Selective Loading and Streaming
    Animations are loaded or stremed into memory just before being nedded and dumped from memory once thye have played.

  - The animation Pipeline
    - def: Operations performed by the low-level animation engine.
    - Stage: First, Clip decompression and pose extraction
             Second, Pose blending.
             Third, Global pose generation
             Fourth, Post-processing
             Fifth, Recalculation of global poses
             Sixth, Matrix palette generation
      ![20240126163005](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240126163005.png)

  - Action State Machines
    - def: A finite state machine models the actions of a game character atop the animation pipeline, providing a state-driven animaiton interface.
    - Each state in an ASM corresponds to an arbitrarily complex blend of simultaneous animation clips (Idle, Running, etc.).
    - characters can *transition* smoothly between states via a smooth *cross-fade*
    - **Anticipation**: Complex movement can be realized by allowing multiple independent state machines to control a single character. Each state machine exists in aseparate *state layer*, the outputs are blended together into a final composite pose via *Flat weighted average* or *Blend tree*.
    ![20240126163917](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240126163917.png)
    - **The Flat Weight Average Approach**
      - def: Maintain a flat list of all *active( weigt are nonzero)* clips, And calculate a simple N-point weighted average of the translation vectors, rotation quaternions and scale factors extracted from the N active animations.
      ![20240126175905](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240126175905.png)
    - **Blend Trees**
      - def: an example of compiler theory as an *expression tree* or a *syntax tree*.
      - Binary LERP Blend Trees
      - Generalized One-Dimensional Blend Trees
      - Two-Dimensional LERP Blend Trees
      - Additive Blend Trees
      - Layered Blend Trees
      - Cross-Fades with Blend Trees
    - State and Blend Tree Specifications
    - Transitions
      - Kinds of Transitions
      - Transition Parameters
      - The Transition Matrix
      - Implementing a Transition Matrix
    - Control Parameters

  - Contraints
    - Attachments
    - Interobject Registration
      - Reference Locators
      - Find World-Space Reference Location
      - Grabbing and Hand IK
    - Motion Extraction and Foot IK
      - Motion Extraction
      - Foot IK
    - Other Kinds of Constraints