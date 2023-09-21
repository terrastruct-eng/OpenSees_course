################################################################################
# Your first OpenSees model
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
    model BasicBuilder -ndm 2 -ndf 3; #ndm: spatial dimension; ndf: DoF per node
                       #2 dimensions, 3 DOF per node

################################################################################
# GLOBAL GEOMETRY
################################################################################

    set Span   6.0;
    set Storey 3.5;

# Main grid lines
    # Vertical axes, x
    set x1 [expr 0.0];
    set x2 [expr $x1+$Span];
# Horizontal axes, z
    set z0 [expr 0.0];
    set z1 [expr $z0+$Storey];      
    set z2 [expr $z1+$Storey];
    
################################################################################
# DEFINITION OF NODES
################################################################################

    #Assigning node tags to variables to facilitate the manipulation of models
    set N_A0     1;
    set N_B0     2;
    set N_A1     3;
    set N_B1     4;
    set N_A2     5;
    set N_B2     6;
    
    set N_A1_PH  7;
    set N_B1_PH  8;
    set N_A2_PH  9;
    set N_B2_PH 10;
    
    #node $nodeTag (ndm $coords) <-mass (ndf $massValues)>
    node    $N_A0          $x1 $z0;
    node    $N_B0          $x2 $z0;
    node    $N_A1          $x1 $z1;
    node    $N_B1          $x2 $z1;
    node    $N_A2          $x1 $z2;  
    node    $N_B2          $x2 $z2;
                    
    node    $N_A1_PH       $x1 $z1;
    node    $N_B1_PH       $x2 $z1;
    node    $N_A2_PH       $x1 $z2;
    node    $N_B2_PH       $x2 $z2;
    
################################################################################
# RESTRAINTS
################################################################################

    #fix $nodeTag (ndf $constrValues)   
    fix     $N_A0       1 1 1;
    fix     $N_B0       1 1 1;
           
################################################################################
# CONSTRAINTS
################################################################################

#Nodes in beam-column connections are linked by a zeroLength element in rotation         
#The rest of the DoF are linked with these contraints

# Panel zones
    #equalDOF $rNodeTag $cNodeTag $dof1 $dof2
    equalDOF  $N_A1     $N_A1_PH    1     2;
    equalDOF  $N_B1     $N_B1_PH    1     2;
    equalDOF  $N_A2     $N_A2_PH    1     2;
    equalDOF  $N_B2     $N_B2_PH    1     2;
    
################################################################################
# MATERIALS
################################################################################
                                 
# Definition of materials IDs
    set S355          1;
    set S355el        2; 
    set lignosIPE220  3;
        
# Basic parameters for S355
    set E0      210000000 ;
    set fy      355000;
    set p       0.01;  
    
# Definition of Steel01 material
    #uniaxialMaterial Steel01 $matTag  $Fy    $E0 $b <$a1 $a2 $a3 $a4>
    uniaxialMaterial  Steel01 $S355    $fy    $E0 $p;

# Definition of Elastic steel
    #uniaxialMaterial Elastic $matTag   $E <$eta> <$Eneg>
#     uniaxialMaterial  Elastic $S355el   $E0;

# Definition of material for plastic hinges
    #uniaxialMaterial   Bilin $matTag          $K0        $as_Plus             $as_Neg                $My_Plus   $My_Neg     [$Lambda S C A K]                                                            [$c S C A K]    $theta_p_Plus         $theta_p_Neg          $theta_pc_Plus       $theta_pc_Neg      $Res_Pos $Res_Neg $theta_u_Plus $theta_u_Neg $D_Plus $D_Neg
    uniaxialMaterial    Bilin $lignosIPE220    64033.2    0.00203545752454409  0.00203545752454409    101.175    -101.175    1.50476106091578    1.50476106091578    1.50476106091578    1.50476106091578    1 1 1 1      0.0853883552651735    0.0853883552651735    0.234610805942179    0.234610805942179  0.4      0.4      0.4           0.4          1       1;

################################################################################
# SECTIONS
################################################################################

# Define sections IDs
    set HE180B   1;
    
# Subroutine for W sections of the columns
    source Wsection.tcl;  #Fibre model builder
    
# Define column dimensions
    set hc1  0.1800;
    set bc1  0.1800;
    set tfc1 0.0140;
    set twc1 0.0085;                                                      
    
# Wsection   $secID     $matID $d   $bf  $tf   $tw   $nfdw  $nftw $nfbf  $nftf
    Wsection $HE180B    $S355  $hc1 $bc1 $tfc1 $twc1 4      2     4      2;  
    
################################################################################
# ELEMENTS
################################################################################

# Definition of transformation IDs
    set PDTrans 1;

# Definition of transformation
    geomTransf PDelta $PDTrans; #P-Delta effect included
    #geomTransf Linear $LNTrans; #P-Delta effect not included
    
# Definition of number of integration points
    set NI  4;   #Maximum number = 10 
    
# Column elements of the MRF
    #element nonlinearBeamColumn $eleTag   $iNode     $jNode     $numIntgrPts $secTag   $transfTag
    element nonlinearBeamColumn    1       $N_A0      $N_A1      $NI          $HE180B   $PDTrans;   
    element nonlinearBeamColumn    2       $N_B0      $N_B1      $NI          $HE180B   $PDTrans; 
    element nonlinearBeamColumn    3       $N_A1      $N_A2      $NI          $HE180B   $PDTrans; 
    element nonlinearBeamColumn    4       $N_B1      $N_B2      $NI          $HE180B   $PDTrans; 

# Beam elements section parameters
    set Ab1 0.00334;
    set Ib1 0.00002772;

# Beam elements of the MRF
    #element elasticBeamColumn $eleTag   $iNode      $jNode       $A   $E  $Iz   $transfTag
    element elasticBeamColumn   5       $N_A1_PH    $N_B1_PH      $Ab1 $E0 $Ib1 $PDTrans;
    element elasticBeamColumn   6       $N_A2_PH    $N_B2_PH      $Ab1 $E0 $Ib1 $PDTrans;
    
# Plastic hinges
    #element zeroLength $eleTag $iNode       $jNode   -mat $matTag1 $matTag2 ... -dir $dir1 $dir2 ...<-doRayleigh $rFlag> <-orient $x1 $x2 $x3 $yp1 $yp2 $yp3>
    element zeroLength  7      $N_A1_PH      $N_A1    -mat $lignosIPE220 -dir 6;  
    element zeroLength  8      $N_B1_PH      $N_B1    -mat $lignosIPE220 -dir 6;  
    element zeroLength  9      $N_A2_PH      $N_A2    -mat $lignosIPE220 -dir 6;
    element zeroLength  10     $N_B2_PH      $N_B2    -mat $lignosIPE220 -dir 6;

################################################################################
# GRAVITY LOADS
################################################################################ 

    #timeSeries "LinearDefault":    tsTag    cFactor 
    timeSeries   Linear             1        -factor +1.000000E+00 
    
    #Distributed loads
    set     DL     20; # kN/m
    set     CL     50; # kN

    #pattern PatternType $PatternID TimeSeriesType
    pattern    Plain        1            1       {
    #load $nodeTag (ndf $LoadValues)
    load  $N_A1 0   [expr -$CL]    0;
    load  $N_B1 0   [expr -$CL]    0; 
    load  $N_A2 0   [expr -$CL]    0;
    load  $N_B2 0   [expr -$CL]    0;
    
    #eleLoad -ele $eleTag1 <$eleTag2 ....> -type -beamUniform $Wy <$Wx>                          
    eleLoad -ele 5 6 -type -beamUniform [expr -$DL]; 
    
    }                                      

################################################################################
# MASSES
################################################################################    

    set mass1   75; # tonf
    set mass2   75;
    
# Assign mass to nodes
    #mass $nodeTag (ndf $massValues)
    mass  $N_A1     [expr $mass1/2]    0    0;
    mass  $N_B1     [expr $mass1/2]    0    0;
    mass  $N_A2     [expr $mass2/2]    0    0;
    mass  $N_B2     [expr $mass2/2]    0    0;                                                                        