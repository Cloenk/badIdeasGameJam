extends Resource
class_name PIDController

## Proportional, contribution of current error
@export_range(0, 10, 0.01, "or_greater") var p_coef: float
## Integral, contribution of accumulated error
@export_range(0, 10, 0.01, "or_greater") var i_coef: float
## Derivative, contribution of change in error
@export_range(0, 10, 0.01, "or_greater") var d_coef: float

## Clamps the magnitude of the integral to prevent "integral windup", where a large change can cause excessive oscillation.
@export_range(0, 100, 0.1, "or_greater") var integral_clamp: float

@export_range(0.001, 1, 0.001, "or_greater", "exp") var smooth_derivative: float


static func new_pid(p: float, i: float, d: float, ic: float, sd: float) -> PIDController:
	var result: PIDController = new()
	result.p_coef = p
	result.i_coef = i
	result.d_coef = d
	result.integral_clamp = ic
	result.smooth_derivative = sd
	return result


var last_error_1d: float
var deriv_smooth_1d: float
var integrator_1d: float

func update_1d(error: float, delta: float) -> float:
	integrator_1d += i_coef * error * delta # scaled first for "bump-less operation"
	integrator_1d = clamp(integrator_1d, -integral_clamp, integral_clamp)
	deriv_smooth_1d = lerp(deriv_smooth_1d, (error - last_error_1d) / delta, smooth_derivative)
	var result = p_coef * error + integrator_1d + d_coef * deriv_smooth_1d
	last_error_1d = error
	return result

func reset_1d():
	last_error_1d = 0
	deriv_smooth_1d = 0
	integrator_1d = 0


var last_error_2d: Vector2
var deriv_smooth_2d: Vector2
var integrator_2d: Vector2

func clamp_mag_2d(value: Vector2, mag: float) -> Vector2:
	if value.length() < mag:
		return value
	else:
		return value.normalized() * mag

func update_2d(error: Vector2, delta: float) -> Vector2:
	integrator_2d += i_coef * error * delta # scaled first for "bump-less operation"
	integrator_2d = clamp_mag_2d(integrator_2d, integral_clamp)
	deriv_smooth_2d = lerp(deriv_smooth_2d, (error - last_error_2d) / delta, smooth_derivative)
	var result = p_coef * error + integrator_2d + d_coef * deriv_smooth_2d
	last_error_2d = error
	return result

func reset_2d():
	last_error_2d = Vector2.ZERO
	deriv_smooth_2d = Vector2.ZERO
	integrator_2d = Vector2.ZERO


var last_error_3d: Vector3
var deriv_smooth_3d: Vector3
var integrator_3d: Vector3

func clamp_mag_3d(value: Vector3, mag: float) -> Vector3:
	if value.length() < mag:
		return value
	else:
		return value.normalized() * mag

func update_3d(error: Vector3, delta: float) -> Vector3:
	integrator_3d += i_coef * error * delta # scaled first for "bump-less operation"
	integrator_3d = clamp_mag_3d(integrator_3d, integral_clamp)
	deriv_smooth_3d = lerp(deriv_smooth_3d, (error - last_error_3d) / delta, smooth_derivative)
	var result = p_coef * error + integrator_3d + d_coef * deriv_smooth_3d
	last_error_3d = error
	return result

func reset_3d():
	last_error_3d = Vector3.ZERO
	deriv_smooth_3d = Vector3.ZERO
	integrator_3d = Vector3.ZERO


var last_error_4d: Vector4
var deriv_smooth_4d: Vector4
var integrator_4d: Vector4

func clamp_mag_4d(value: Vector4, mag: float) -> Vector4:
	if value.length() < mag:
		return value
	else:
		return value.normalized() * mag

func update_4d(error: Vector4, delta: float) -> Vector4:
	integrator_4d += i_coef * error * delta # scaled first for "bump-less operation"
	integrator_4d = clamp_mag_4d(integrator_4d, integral_clamp)
	deriv_smooth_4d = lerp(deriv_smooth_4d, (error - last_error_4d) / delta, smooth_derivative)
	var result = p_coef * error + integrator_4d + d_coef * deriv_smooth_4d
	last_error_4d = error
	return result

func reset_4d():
	last_error_4d = Vector4.ZERO
	deriv_smooth_4d = Vector4.ZERO
	integrator_4d = Vector4.ZERO
