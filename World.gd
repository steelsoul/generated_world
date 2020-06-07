extends Spatial

const chunk_size = 64
const chunk_amount = 16

onready var THREAD_AMOUNT = 2# OS.get_processor_count() / 4
const CHUNKS_BLOCKS = 1

var noise
var chunks = {}
var unready_chunks = {}
var threads = []

var prepared_chunks = []

var next_avail_thread

func _ready():
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 6
	noise.period = 80
	
	for i in range(0, THREAD_AMOUNT):
		threads.append(Thread.new())

func get_available_thread():
	if next_avail_thread and not next_avail_thread.is_active():
		return next_avail_thread
	for i in range(0, THREAD_AMOUNT):
		if not threads[i].is_active():
			if i < THREAD_AMOUNT-1:
				next_avail_thread = threads[i+1]
			return threads[i]
	return null
	
func add_chunk(x, z):
	var key = _get_key(x, z)
	if chunks.has(key) or unready_chunks.has(key):
		return
	
	var thread = get_available_thread()

	if thread != null:
		thread.start(self, "load_chunk", [thread, x, z])
		unready_chunks[key] = 1
		
func load_chunk(arr):
	
	var thread = arr[0]
	var x = arr[1]
	var z = arr[2]
	
	#print("load_chunk %d %d %s" % [x, z, thread.get_id()])
	
	var chunk = Chunk.new(noise, x * chunk_size, z * chunk_size, chunk_size)
	chunk.translation = Vector3(x * chunk_size, 0, z*chunk_size)

	call_deferred("load_done", chunk, thread)
	
func load_done(chunk, thread):
	prepared_chunks.append(chunk)
	#print("TA: %d" % prepared_chunks.size())
	if prepared_chunks.size() == CHUNKS_BLOCKS:
		for chunk in prepared_chunks:
			var key = _get_key(chunk.x / chunk_size, chunk.z / chunk_size)
			chunks[key] = chunk
			add_child(chunk)
			unready_chunks.erase(key)
		prepared_chunks.clear()
	thread.wait_to_finish()
	
	
func get_chunk(x, z):
	var key = _get_key(x, z)
	if chunks.has(key):
		return chunks.get(key)
		
	return null

func _get_key(x, z):
	return str(x) + "," + str(z)
	
func _process(delta):
	update_chunks()
#	clean_up_chunks()
#	reset_chunks()
	
func update_chunks():
	
	var player_translation = $Player.translation
	var px = int(player_translation.x) / chunk_size
	var pz = int(player_translation.z) / chunk_size	
	
	for x in range(px - chunk_amount * 0.5, px + chunk_amount * 0.5):
		for z in range(pz - chunk_amount * 0.5, pz + chunk_amount * 0.5):
			add_chunk(x, z)
			var chunk = get_chunk(x, z)
			if chunk != null:
				chunk.should_remove = false

func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			chunk.queue_free()
			chunks.erase(key)
	
	
func reset_chunks():
	for key in chunks:
		chunks[key].should_remove  = true
	
	
	
	
	
	
	
	
	
	
	
	
		
