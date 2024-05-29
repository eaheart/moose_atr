mu = 1
rho = 1000
cp = 4182
u_inlet = -6
T_inlet = 52
k_fluid = 1
k_solid = 100
h_cv = 3.72e+06
advected_interp_method = 'upwind'
velocity_interp_method = 'rc'

[Mesh]
  [mesh]
    type = CartesianMeshGenerator
    dim = 2
    dx = '0.6096'
    dy = '4.5 1.2192 4.5'
    ix = '20'
    iy = '50 20 50'
    subdomain_id = '1 2 3'
  []
  [shift_down]
    type = TransformGenerator
    input = mesh
    transform = TRANSLATE
    vector_value = '0 -4.5 0'

  []
  coord_type = 'RZ'
  rz_coord_axis = 'Y'
[]

[GlobalParams]
  rhie_chow_user_object = 'rc'
  porosity = porosity
[]

[UserObjects]
  [rc]
    type = PINSFVRhieChowInterpolator
    u = superficial_vel_x
    v = superficial_vel_y
    pressure = pressure
    porosity = porosity
  []
[]

[Variables]
  [superficial_vel_x]
    type = PINSFVSuperficialVelocityVariable
    initial_condition = 1e-6
  []
  [superficial_vel_y]
    type = PINSFVSuperficialVelocityVariable
    initial_condition = ${u_inlet}
  []
  [pressure]
    type = INSFVPressureVariable
  []
  [T_fluid]
    type = INSFVEnergyVariable
    initial_condition = 52
  []
  [T_solid]
   type = INSFVEnergyVariable
   initial_condition = 52
   block = 2
  []
[]

[AuxVariables]
  [porosity]
    type = MooseVariableFVReal
  []
[]

[ICs]
  inactive = 'porosity_continuous'
  [porosity_1]
    type = ConstantIC
    variable = porosity
    block = 1
    value = 0.95
  []
  [porosity_2]
    type = ConstantIC
    variable = porosity
    block = 2
    value = 0.44
  []
  [porosity_3]
    type = ConstantIC
    variable = porosity
    block = 3
    value = 0.95
  []
  [porosity_continuous]
    type = FunctionIC
    variable = porosity
    block = '1 2 3'
    function = smooth_jump
  []
[]


[FVKernels]
  [heat_source]
    type = FVBodyForce
    variable = T_solid
    function = force
    block = 2
  []
  [mass]
    type = PINSFVMassAdvection
    variable = pressure
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
  []
  [u_advection]
    type = PINSFVMomentumAdvection
    variable = superficial_vel_x
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    porosity = porosity
    momentum_component = 'x'
  []
  [u_viscosity]
    type = PINSFVMomentumDiffusion
    variable = superficial_vel_x
    mu = ${mu}
    porosity = porosity
    momentum_component = 'x'
  []
  [u_pressure]
    type = PINSFVMomentumPressure
    variable = superficial_vel_x
    momentum_component = 'x'
    pressure = pressure
    porosity = porosity
  []
  [u_friction]
    type = PINSFVMomentumFriction
    variable = superficial_vel_x
    momentum_component = 'x'
    Darcy_name = 'Darcy_coefficient'
    Forchheimer_name = 'Forchheimer_coefficient'
    mu = ${mu}
    rho = ${rho}
    speed = speed
  []
  [v_advection]
    type = PINSFVMomentumAdvection
    variable = superficial_vel_y
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    porosity = porosity
    momentum_component = 'y'
  []
  [v_viscosity]
    type = PINSFVMomentumDiffusion
    variable = superficial_vel_y
    mu = ${mu}
    porosity = porosity
    momentum_component = 'y'
  []
  [v_pressure]
    type = PINSFVMomentumPressure
    variable = superficial_vel_y
    momentum_component = 'y'
    pressure = pressure
    porosity = porosity
  []
  [v_friction]
  type = PINSFVMomentumFriction
  variable = superficial_vel_y
  momentum_component = 'y'
  Darcy_name = 'Darcy_coefficient'
  Forchheimer_name = 'Forchheimer_coefficient'
  rho = ${rho}
  speed = speed
  mu = ${mu}
  []
  [energy_advection]
    type = PINSFVEnergyAdvection
    variable = T_fluid
    velocity_interp_method = ${velocity_interp_method}
    advected_interp_method = ${advected_interp_method}
  []
  [energy_diffusion]
    type = PINSFVEnergyDiffusion
    k = ${k_fluid}
    variable = T_fluid
    porosity = porosity
  []
  [energy_convection]
    type = PINSFVEnergyAmbientConvection
    variable = T_fluid
    is_solid = false
    T_fluid = 'T_fluid'
    T_solid = 'T_solid'
    h_solid_fluid = 'h_cv'
    block = 2
  []
  [solid_energy_diffusion]
    type = FVDiffusion
    coeff = ${k_solid}
    variable = T_solid
  []
  [solid_energy_convection]
    type = PINSFVEnergyAmbientConvection
    variable = T_solid
    is_solid = true
    T_fluid = 'T_fluid'
    T_solid = 'T_solid'
    h_solid_fluid = 'h_cv'
  []
[]

[Functions]
  [force]
    type = ParsedFunction
    expression = 182.59*10^6*cos((pi/(2*0.6096))*x)*sin((pi/1.2192)*y)
  []
[]

[FVBCs]
  [inlet-u]
    type = INSFVInletVelocityBC
    boundary = 'top'
    variable = superficial_vel_x
    function = 0
  []
  [inlet-v]
    type = INSFVInletVelocityBC
    boundary = 'top'
    variable = superficial_vel_y
    function = ${u_inlet}
  []
  [inlet-T]
    type = FVNeumannBC
    variable = T_fluid
    value = '${fparse -u_inlet * rho * cp * T_inlet}'
    boundary = 'top'
  []

  [walls-u]
    type = INSFVNaturalFreeSlipBC
    boundary = 'right'
    variable = superficial_vel_x
    momentum_component = 'x'
  []
  [walls-v]
    type = INSFVNaturalFreeSlipBC
    boundary = 'right'
    variable = superficial_vel_y
    momentum_component = 'y'
  []

  [symmetry-u]
    type = PINSFVSymmetryVelocityBC
    boundary = 'left'
    variable = superficial_vel_x
    u = superficial_vel_x
    v = superficial_vel_y
    mu = ${mu}
    momentum_component = 'x'
  []
  [symmetry-v]
    type = PINSFVSymmetryVelocityBC
    boundary = 'left'
    variable = superficial_vel_y
    u = superficial_vel_x
    v = superficial_vel_y
    mu = ${mu}
    momentum_component = 'y'
  []
  [symmetry-p]
    type = INSFVSymmetryPressureBC
    boundary = 'left'
    variable = pressure
  []

  [outlet-p]
    type = INSFVOutletPressureBC
    boundary = 'bottom'
    variable = pressure
    function = 0
  []
[]

[FunctorMaterials]
  [constants]
    type = ADGenericFunctorMaterial
    prop_names = 'h_cv'
    prop_values = '${h_cv}'
  []
  [functor_constants]
    type = ADGenericFunctorMaterial
    prop_names = 'cp'
    prop_values = '${cp}'
  []
  [ins_fv]
    type = INSFVEnthalpyFunctorMaterial
    rho = ${rho}
    temperature = 'T_fluid'
  []
  [darcy]
    type = ADGenericVectorFunctorMaterial
    prop_names = 'Darcy_coefficient Forchheimer_coefficient'
    prop_values = '0.1 0.1 0.1 0.1 0.1 0.1'
  []
  [speec]
    type = PINSFVSpeedFunctorMaterial
    superficial_vel_x = superficial_vel_x
    superficial_vel_y = superficial_vel_y
    porosity = porosity
  []
[]

[Executioner]
  type = Steady
  solve_type = 'NEWTON'
  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = 'lu NONZERO'
  nl_rel_tol = 1e-6
[]

# Some basic Postprocessors to examine the solution
[Postprocessors]
  [inlet-p]
    type = SideAverageValue
    variable = pressure
    boundary = 'top'
  []
  [outlet-u]
    type = SideAverageValue
    variable = superficial_vel_x
    boundary = 'bottom'
  []
  [outlet-temp]
    type = SideAverageValue
    variable = T_fluid
    boundary = 'bottom'
  []
  [solid-temp]
    type = ElementAverageValue
    variable = T_solid
    block = 2
  []

[]

[Outputs]
  exodus = true
  csv = false
[]
