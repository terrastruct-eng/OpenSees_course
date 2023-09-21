################################################################################
# Concrete frame
# By Luis Fernando Gutiérrez Urzúa
# Units: kN, m, sec
################################################################################

################################################################################
# SET UP OF WORKSPACE
################################################################################

    wipe
    
# Define model builder
# http://opensees.berkeley.edu/wiki/index.php/Model_command
#   model BasicBuilder -ndm $ndm <-ndf $ndf>
    model BasicBuilder -ndm 3 -ndf 6; #ndm: spatial dimension; ndf: DoF per node
                       #3 dimensions, 6 DOF per node

################################################################################
# GLOBAL GEOMETRY
################################################################################

    set Span_X   6.0;
    set Span_Y   7.0;
    set Storey_Z   3.5;

# Main grid lines
    # Axes in x
    set x1 [expr 0.0];
    set x2 [expr $x1+$Span_X];  
    # Axes in y
    set y1 [expr 0.0];
    set y2 [expr $y1+$Span_Y];
    # Axes in z
    set z0 [expr 0.0];
    set z1 [expr $z0+$Storey_Z];  
    
################################################################################
# DEFINITION OF NODES
################################################################################

    #Assigning node tags to variables to facilitate the manipulation of models
    set N_A0     1;
    set N_B0     2;
    set N_C0     3;
    set N_D0     4;
    set N_A1     5;
    set N_B1     6; 
    set N_C1     7;
    set N_D1     8;
    
    #node $nodeTag (ndm $coords) <-mass (ndf $massValues)>
    node    $N_A0          $x1 $y1 $z0;
    node    $N_B0          $x2 $y1 $z0;
    node    $N_C0          $x1 $y2 $z0;
    node    $N_D0          $x2 $y2 $z0;
    node    $N_A1          $x1 $y1 $z1;  
    node    $N_B1          $x2 $y1 $z1; 
    node    $N_C1          $x1 $y2 $z1;  
    node    $N_D1          $x2 $y2 $z1;
    
################################################################################
# RESTRAINTS
################################################################################

    #fix $nodeTag (ndf $constrValues)   
    fix     $N_A0       1 1 1 1 1 1;
    fix     $N_B0       1 1 1 1 1 1;    
    fix     $N_C0       1 1 1 1 1 1;
    fix     $N_D0       1 1 1 1 1 1;
           
################################################################################
# CONSTRAINTS
################################################################################

# None
    
################################################################################
# MATERIALS
################################################################################
                                 
# Definition of materials IDs
    set C_unconf  1;
    set C_conf    2; 
    set R_steel   3;
        
# Basic parameters for materials
    set fc_1    -25000;  #f'c in compression for unconfined concrete
    set fc_2    -28000;  #f'c in compression for confined concrete  
    set epsc    -0.002;  #strain at maximum stress in compression 
    set fu_1    [expr $fc_1*0.2];  #ultimate stress for unconfined concrete
    set fu_2    [expr $fc_2*0.2];  #ultimate stress for confined concrete
    set epsu    -0.02;   #strain at ultimate stress in compression
    set lambda     0.1;  #ratio between reloading stiffness and initial stiffness in compression
    set ft_1    [expr $fc_1*-0.1];  #maximum stress in tension for unconfined concrete
    set ft_2    [expr $fc_2*-0.1];  #maximum stress in tension for confined concrete
    set Et_1    [expr $ft_1/0.002]; #Elastic modulus in tension for unconfined concrete 
    set Et_2    [expr $ft_2/0.002]; #Elastic modulus in tension for confined concrete
    # E in compression is calculated automatically depending on other material properties
    
    set fy    420000;  #fy for reinforcing steel
    set Es 210000000;  #E for reinforcing steel
    set b      0.005;  #strain hardening ratio
    set R0        20;  #smoothness of the elastic-to-plastic transition
    set cR1    0.925;  #smoothness of the elastic-to-plastic transition	
    set cR2	    0.15;  #smoothness of the elastic-to-plastic transition    
    
# Definition of Concrete02 material
    #uniaxialMaterial Concrete02 $matTag   $fpc   $epsc0 $fpcu $epsU $lambda $ft   $Ets
    uniaxialMaterial  Concrete02 $C_unconf $fc_1  $epsc  $fu_1 $epsu $lambda $ft_1 $Et_1; 
    uniaxialMaterial  Concrete02 $C_conf   $fc_2  $epsc  $fu_2 $epsu $lambda $ft_2 $Et_2;

# Definition of Steel02 steel
    #uniaxialMaterial Steel02 $matTag  $Fy $E  $b $R0 $cR1 $cR2 <$a1 $a2 $a3 $a4 $sigInit>
    uniaxialMaterial  Steel02 $R_steel $fy $Es $b $R0 $cR1 $cR2

################################################################################
# SECTIONS
################################################################################

# Define sections IDs
    set Col300x400   1;
    set Beam300x600  2;
    
# Define dimensions                   
    set pi        [expr acos(-1.0)] ;           
    set Rebar_25  [expr $pi*0.025*0.025/4];  #area rebar 25mm
    set b_col       0.3; #column base
    set h_col       0.4; #column height
    set r_col      0.04; #column cover
    set b_beam      0.3; #beam base      
    set h_beam      0.6; #beam height
    set r_beam     0.04; #beam cover

# Load procedure
    source BuildRCrectSection.tcl
   
# Build sections
    #BuildRCrectSection	$ColSecTag   $HSec   $BSec   $coverH  $coverB  $IDconcCore $IDconcCover $IDSteel $numBarsTop $barAreaTop $numBarsBot $barAreaBot $numBarsIntTot $barAreaInt $nfCoreY  $nfCoreZ  $nfCoverY  $nfCoverZ
    BuildRCrectSection  $Col300x400  $h_col  $b_col  $r_col   $r_col   $C_conf     $C_unconf    $R_steel 3           $Rebar_25   3           $Rebar_25   4              $Rebar_25   8         8         8          8
    BuildRCrectSection  $Beam300x600 $h_beam $b_beam $r_beam  $r_beam  $C_conf     $C_unconf    $R_steel 3           $Rebar_25   3           $Rebar_25   4              $Rebar_25   8         8         8          8
                                      
################################################################################
# ELEMENTS
################################################################################

# Definition of transformation IDs
    set PDTransCol 1;
    set LTransBeaX 2;
    set LTransBeaY 3;

# Definition of transformation                               
    #geomTransf PDelta $transfTag  $vecxzX $vecxzY $vecxzZ <-jntOffset $dXi $dYi $dZi $dXj $dYj $dZj>
    geomTransf  PDelta $PDTransCol   -1      0        0     ; #P-Delta effects included  
    geomTransf  Linear $LTransBeaX   0       1        0     ; #   
    geomTransf  Linear $LTransBeaY   1       0        0     ; #
    
# Definition of number of integration points
    set NI  8;   #Maximum number = 10 
    
# Column elements of the MRF
    #element nonlinearBeamColumn $eleTag   $iNode     $jNode     $numIntgrPts $secTag      $transfTag
    element nonlinearBeamColumn    1       $N_A0      $N_A1      $NI          $Col300x400  $PDTransCol;   
    element nonlinearBeamColumn    2       $N_B0      $N_B1      $NI          $Col300x400  $PDTransCol; 
    element nonlinearBeamColumn    3       $N_C0      $N_C1      $NI          $Col300x400  $PDTransCol;   
    element nonlinearBeamColumn    4       $N_D0      $N_D1      $NI          $Col300x400  $PDTransCol; 

# Beam elements of the MRF
    #element nonlinearBeamColumn $eleTag   $iNode     $jNode     $numIntgrPts $secTag       $transfTag
    element nonlinearBeamColumn    5       $N_A1      $N_B1      $NI          $Beam300x600  $LTransBeaX;   
    element nonlinearBeamColumn    6       $N_C1      $N_D1      $NI          $Beam300x600  $LTransBeaX; 
    element nonlinearBeamColumn    7       $N_A1      $N_C1      $NI          $Beam300x600  $LTransBeaY;   
    element nonlinearBeamColumn    8       $N_B1      $N_D1      $NI          $Beam300x600  $LTransBeaY; 

################################################################################
# GRAVITY LOADS
################################################################################ 

    #timeSeries "LinearDefault":    tsTag    cFactor 
    timeSeries   Linear             1        -factor +1.000000E+00 
    
    #Distributed loads
    set     CL     80; # kN

    #pattern PatternType $PatternID TimeSeriesType
    pattern    Plain        1            1       {
    #load $nodeTag (ndf $LoadValues)
    load  $N_A1 0 0  [expr -$CL]    0 0 0;
    load  $N_B1 0 0  [expr -$CL]    0 0 0; 
    load  $N_C1 0 0  [expr -$CL]    0 0 0;
    load  $N_D1 0 0  [expr -$CL]    0 0 0;
    
    }                                      

################################################################################
# MASSES
################################################################################    

    set mass1   200; # tonf
    
# Assign mass to nodes
    #mass $nodeTag (ndf $massValues)
    mass  $N_A1     [expr $mass1/4]    [expr $mass1/4]    0 0 0 0;
    mass  $N_B1     [expr $mass1/4]    [expr $mass1/4]    0 0 0 0;
    mass  $N_C1     [expr $mass1/4]    [expr $mass1/4]    0 0 0 0;
    mass  $N_D1     [expr $mass1/4]    [expr $mass1/4]    0 0 0 0;                                                                       