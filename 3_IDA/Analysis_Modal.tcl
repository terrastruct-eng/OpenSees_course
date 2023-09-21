
################################################################################
# START ANALYSIS
################################################################################
 
initialize 

puts "ooo Analysis: ModalAnalysis ooo" 

################################################################################
# SET RECORDERS
################################################################################

# Node Recorder "EigenVectors":    fileName    <nodeTag>    dof    respType 
recorder  Node -file ModalAnalysis_Node_EigenVectors_EigenVec1.out  -node $N_A0 $N_A1 $N_A2  -dof 1  eigen1 
recorder  Node -file ModalAnalysis_Node_EigenVectors_EigenVec2.out  -node $N_A0 $N_A1 $N_A2  -dof 1  eigen2 

################################################################################
# ANALYSIS OPTIONS
################################################################################

# Constraint Handler 
constraints  Transformation 
# DOF Numberer 
numberer  Plain 
# System of Equations 
system  BandGeneral 
# Convergence Test 
test  NormDispIncr  +1.000000E-12    25     0     2 
# Solution Algorithm 
algorithm  Newton 
# Integrator 
integrator  Newmark  +5.000000E-01  +2.500000E-01 
# Analysis Type 
analysis  Transient 

# Analyze model (and record response)
set pi [expr acos(-1.0)] 
set eigFID [open ModalAnalysis_Node_EigenVectors_EigenVal.out w]  
set lambda [eigen     2]     
puts $eigFID " lambda          omega           period          frequency" 
foreach lambda $lambda { 
    set omega [expr sqrt($lambda)] 
    set period [expr 2.0*$pi/$omega] 
    set frequ [expr 1.0/$period] 
    puts $eigFID [format " %+2.6e  %+2.6e  %+2.6e  %+2.6e" $lambda $omega $period $frequ] 
} 
close $eigFID 

# Record eigenvectors 
record 

# Reset for next analysis case 
# ---------------------------- 
setTime 0.0 
loadConst 
remove recorders 
wipeAnalysis 
