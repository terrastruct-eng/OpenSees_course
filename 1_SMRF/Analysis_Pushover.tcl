
################################################################################
# START ANALYSIS
################################################################################

puts "ooo Analysis: Pushover ooo" 

################################################################################
# SET RECORDERS
################################################################################

# Global behaviour
recorder  Node  -file Pushover_Horizontal_Reactions.out  -time  -node $N_A0 $N_B0 -dof 1  reaction
recorder  Node  -file Pushover_Storey_Displacement.out  -time  -node $N_A1 $N_A2 -dof 1 disp    

# Local behaviour
                                         
recorder  Element  -file Pushover_BeamHinge_GlbForc.out  -time  -ele 7 8 9 10  force 
recorder  Element  -file Pushover_BeamHinge_Deformation.out  -time  -eleRange 7 10  deformation   

recorder  Element  -file Pushover_Column_GlbForc.out   -time  -eleRange 1 4  globalForce
recorder  Element  -file Pushover_Column_ChordRot.out  -time  -ele 1 2 3 4  chordRotation         

################################################################################
# ANALYSIS
################################################################################ 

set tStart [clock clicks -milliseconds] 

# Apply lateral load based on first mode shape in x direction (EC8-1)
set phi1 0.046285;
set phi2 0.106636; 
  # pattern PatternType $PatternID TimeSeriesType
    pattern    Plain        2             1      {
    # load $nodeTag (ndf $LoadValues)
      load    $N_A1     [expr $mass1*$phi1] 0.0 0.0 
      load    $N_B1     [expr $mass1*$phi1] 0.0 0.0 
      load    $N_A2     [expr $mass2*$phi2] 0.0 0.0 
      load    $N_B2     [expr $mass2*$phi2] 0.0 0.0 
    };

# Define step parameters
 set step +1.000000E-04; 
 set numbersteps  5000;

# Constraint Handler 
constraints  Transformation 
# DOF Numberer 
numberer  RCM 
# System of Equations 
system  BandGeneral 
# Convergence Test           
test  NormDispIncr  0.000001   100   
#algorithm NewtonLineSearch <-type $typeSearch> <-tol $tol> <-maxIter $maxIter> <-minEta $minEta> <-maxEta $maxEta> 
algorithm  NewtonLineSearch -type Bisection -tol +8E-1 -maxIter 1000 -minEta 1E-1 -maxEta 1E1 pFlag 1 
#integrator DisplacementControl $node $dof $incr <$numIter $?Umin $?Umax>            100 +5.000000E-08 +5.000000E-06   
integrator  DisplacementControl    $N_A2     1  $step 
# Analysis Type 
analysis  Static 

# Record initial state of model  
record

# Analyze model 
analyze  $numbersteps 

# Stop timing of this analysis sequence 
set tStop [clock clicks -milliseconds] 
puts "o Time taken: [expr ($tStop-$tStart)/1000.0] sec" 

# Reset for next analysis sequence 
wipe 
