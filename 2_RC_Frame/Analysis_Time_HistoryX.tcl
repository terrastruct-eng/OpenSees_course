
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
recorder  Node  -file TimeHistory_Horizontal_ReactionsX.$k.$j.out  -time  -node $N_A0 $N_B0 $N_C0 $N_D0 -dof 1 reaction
recorder  Node  -file TimeHistory_Storey_DisplacementX.$k.$j.out  -time  -node $N_A1 $N_B1 $N_C1 $N_D1  -dof 1 disp  
recorder  Node  -file TimeHistory_Storey_AccelerationX.$k.$j.out  -time  -node $N_A1 $N_B1 $N_C1 $N_D1  -dof 1 accel    

################################################################################
# DAMPING COEFICIENTS
################################################################################ 

set xi1 0.05;
set T1  +4.907470e-01;
set omega1 [expr 2*$pi/$T1];
set aR [expr 0];
set bR [expr 2*$xi1/$omega1];

################################################################################
# GROUND MOTION INPUT
################################################################################ 

set lambda 1; #Scaling of the GM (multiplies the original file accelerations)
set dt 0.02;  #Time step from the GM
set numstep  1750;   #Number of steps in the GM
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