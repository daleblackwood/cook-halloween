class_name Maths

static func dease(dt: float, sharpness: float) -> float:
	return clamp(1.0 - pow(1.0 - sharpness, dt * 60.0), 0.0, 1.0)
