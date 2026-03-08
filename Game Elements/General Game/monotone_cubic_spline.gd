class_name MonotoneCubicSpline

var xs = []   # Sorted x-values
var ys = []   # Corresponding y-values
var ms = []   # Slopes between points
var cs = []   # Cubic coefficients for interpolation

func add_point(x: float, y: float) -> void:
	xs.append(x)
	ys.append(y)

func build() -> void:
	# Sort points by x
	var paired = []
	for i in range(xs.size()):
		paired.append( { "x": xs[i], "y": ys[i] } )
	paired.sort_custom(func(a,b): return false if a["x"] < b["x"] else true)

	xs.clear()
	ys.clear()
	for p in paired:
		xs.append(p["x"])
		ys.append(p["y"])

	var n = xs.size()
	if n < 2:
		return

	# Compute slopes between points
	ms.resize(n-1)
	for i in range(n-1):
		ms[i] = (ys[i+1] - ys[i]) / (xs[i+1] - xs[i])

	# Compute cubic coefficients (Fritsch–Carlson method)
	cs.resize(n)
	cs[0] = ms[0]
	for i in range(1, n-1):
		if ms[i-1] * ms[i] <= 0:
			cs[i] = 0
		else:
			cs[i] = 3 * ms[i-1] * ms[i] / (ms[i-1] + ms[i])
	cs[n-1] = ms[n-2]

func interpolate(x: float) -> float:
	var n = xs.size()
	if n == 0:
		return 0
	if x <= xs[0]:
		return ys[0]
	if x >= xs[n-1]:
		return ys[n-1]

	# Find the segment
	var i = 0
	while i < n-1 and xs[i+1] < x:
		i += 1

	var h = xs[i+1] - xs[i]
	var t = (x - xs[i]) / h
	var t2 = t * t
	var t3 = t2 * t

	var h00 = 2*t3 - 3*t2 + 1
	var h10 = t3 - 2*t2 + t
	var h01 = -2*t3 + 3*t2
	var h11 = t3 - t2

	return h00*ys[i] + h10*h*cs[i] + h01*ys[i+1] + h11*h*cs[i+1]
