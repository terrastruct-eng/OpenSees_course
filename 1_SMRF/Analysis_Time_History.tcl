
################################################################################
# START ANALYSIS
################################################################################

puts "ooo Analysis: Non-linear Time History Analysis ooo" 

################################################################################
# SET RECORDERS
################################################################################

set k 1; #Groundmotion id (in case you run many GMs, like in an IDA)
set j 1; #Scaling id (in case you run many GMs, like in an IDA)
     
# Global behaviour
recorder  Node  -file TimeHistory_Horizontal_Reactions.$k.$j.out  -time  -node $N_A0 $N_B0 -dof 1  reaction
recorder  Node  -file TimeHistory_Storey_Displacement.$k.$j.out  -time  -node $N_A1 $N_A2 -dof 1 disp    

# Local behaviour
                                         
recorder  Element  -file TimeHistory_BeamHinge_GlbForc.$k.$j.out  -time  -ele 7 8 9 10  force 
recorder  Element  -file TimeHistory_BeamHinge_Deformation.$k.$j.out  -time  -eleRange 7 10  deformation   

recorder  Element  -file TimeHistory_Column_GlbForc.$k.$j.out   -time  -eleRange 1 4  globalForce
recorder  Element  -file TimeHistory_Column_ChordRot.$k.$j.out  -time  -ele 1 2 3 4  chordRotation   

################################################################################
# RAYLEIGH DAMPING COEFICIENTS
################################################################################ 

set xi1 0.03;
set xi2 0.03;
set T1  2.301709e+00;
set T2  6.169362e-01;
set pi [expr acos(-1.0)]; 
set omega1 [expr 2*$pi/$T1];
set omega2 [expr 2*$pi/$T2];
set aR [expr 2*($omega1*$omega2*($omega2*$xi1-$omega1*$xi2))/($omega2**2-$omega1**2)];
set bR [expr 2*($omega2*$xi2-$omega1*$xi1)/($omega2**2-$omega1**2)];

################################################################################
# GROUND MOTION INPUT
################################################################################ 

set lambda 1; #Scaling of the GM (multiplies the original file accelerations)
set dt 0.02;  #Time step from the GM
set numstep  6047;   #Number of steps in the GM
# Define time series 
# TimeSeries "TimeSeries01":         dt           filePath 			  cFactor            
set    TimeSeries01  "Series      -dt $dt   -filePath  acc_$k.txt -factor  $lambda"

################################################################################
# ANALYSIS PARAMETERS
################################################################################ 
  
# Define analysis options (Transient)
# Definition of the tolerance and of the maximum number of iteration
set Tol 1.0E-6
set maxIter 5000 
# Convergence Test  
# test NormDispIncr   $tol   $iter 
test   NormDispIncr   $Tol   $maxIter   0    0   
# Define load pattern 
# pattern UniformExcitation $patternTag $dir -accel  $tsTag <-vel0 $vel0> <-fact $cFactor>
pattern   UniformExcitation 3           1    -accel  $TimeSeries01                                           
# Constraint Handler 
constraints  Transformation   
# Integrator 
# integrator Newmark   $gamma          $beta 
integrator   Newmark  +5.000000E-001  +2.500000E-001
# Rayleigh Damping
# rayleigh $alphaM $betaK $betaKinit      $betaKcomm    
rayleigh   $aR     $bR   +0.000000E+000  +0.000000E+000         
# Solution Algorithm (default minEta=0.1 & maxEta=10, default tol=0.8 & maxIter=10)
# algorithm NewtonLineSearch <-type $typeSearch> <-tol $tol> -maxIter    $maxIter  <-minEta $minEta>        <-maxEta $maxEta> 
algorithm   NewtonLineSearch  -type Bisection     -tol 0.8   -maxIter    100       -minEta  +1.000000E-001  -maxEta  +1.000000E+001   
# DOF Numberer 
numberer  RCM 
# System of Equations 
system  BandGeneral
# Analysis Type
analysis  Transient 

set begin [clock clicks -milliseconds]      

################################################################################
# ANALYSIS
################################################################################
 
# First Strategy based on test displacement and NewtonLineSearch algoritm (for m)
# Initial variables before starting dynamic analysis
set ok 0;
set t 0;
set startTime [clock clicks -milliseconds];
set finalt [expr [getTime]+[expr $numstep*$dt]];
set DtAnalysis [expr 0.1*$dt];
puts "Analysis_1  k $k  j $j  lambda $lambda  Dt $DtAnalysis  Tol $Tol  Algorithm NewtonLineSearch -type Bisection"
while {$ok == 0 && $t <= $finalt} {	
  set ok [analyze 1 $DtAnalysis]
  set t [getTime]  	
  # Update the time
  set currentTime [getTime]
  }			  
set finishTime   [clock clicks -milliseconds];
set timeSeconds  [expr ($finishTime-$startTime)/1000];
set timeMinutes  [expr ($timeSeconds/60)];
set timeHours    [expr ($timeSeconds/3600)];
set timeMinutes  [expr ($timeMinutes - $timeHours*60)];
set timeSeconds  [expr ($timeSeconds - $timeMinutes*60 - $timeHours*3600)];  
if {$ok == 0} {
  puts "################################################"
  puts " Analysis   k $k  j $j  lambda $lambda completed SUCCESSFULLY";
  puts "Time in hours-min-sec: $timeHours:$timeMinutes:$timeSeconds"
  puts "################################################"
} else {
  puts "################################################"
  puts "Analysis    k $k  j $j  lambda $lambda  FAILED";  
  puts "Time in hours-min-sec: $timeHours:$timeMinutes:$timeSeconds"  
  puts "################################################"
}
# Final clean up 
wipe 