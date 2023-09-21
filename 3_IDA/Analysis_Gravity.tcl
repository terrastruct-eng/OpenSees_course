
################################################################################
# START ANALYSIS
################################################################################

initialize 

puts "ooo Analysis: Gravity ooo" 

################################################################################
# SET RECORDERS
################################################################################

# Node Recorder "Reactions":    fileName    <nodeTag>    dof    respType 
recorder  Node  -file Gravity_Reactions.out  -time  -node $N_A0 $N_B0  -dof 1 2 3 reaction

################################################################################
# ANALYSIS OPTIONS
################################################################################

# Constraint Handler 
constraints Plain
# DOF Numberer                                
numberer  RCM 
# System of Equations  
system  ProfileSPD 
# Convergence Test 
test  NormDispIncr    +1.000000E-006   100      0        2;    
# Solution Algorithm 
algorithm  Newton 
# Integrator
#integrator LoadControl $lambda <$numIter $minLambda $maxLambda>  
integrator  LoadControl  +0.1 
# Analysis Type 
analysis  Static 

# Record initial state of model 
record

# Analyze model 
analyze    10 

# Reset for next analysis case 
# ---------------------------- 
setTime 0.0 
loadConst 
remove recorders 
wipeAnalysis 