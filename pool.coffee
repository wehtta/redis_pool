
priorityQueue = () ->
	prio_array = []
	enqueue: (obj, priority=1)->
		objWithPrio = {"obj" : obj, "priority": priority}
		min = max =0 

		if(prio_array.length == 0)
			return prio_array[0]=objWithPrio
		loop
			break if min > max
			mid = (min+max) /2		
			min = mid+1 if (priority > prio_array[mid].priority )
			max = mid-1 if (priority < prio_array[mid].priority)
		prio_array.splice mid, 0, objWithPrio

	dequeue: ()->

		if prio_array.length > 0
			return prio_array.shift()["obj"]
	size: () ->
		return prio_array.length
# priorityQueue = (size) ->
#   me = {}
#   slots = undefined
#   i = undefined
#   total = null
  
#   # initialize arrays to hold queue elements
#   size = Math.max(+size | 0, 1)
#   slots = []
#   i = 0
#   while i < size
#     slots.push []
#     i += 1
  
#   #  Public methods
#   me.size = ->
#     i = undefined
#     if total is null
#       total = 0
#       i = 0
#       while i < size
#         total += slots[i].length
#         i += 1
#     total

#   me.enqueue = (obj, priority) ->
#     priorityOrig = undefined
    
#     # Convert to integer with a default value of 0.
#     priority = priority and +priority | 0 or 0
    
#     # Clear cache for total.
#     total = null
#     if priority
#       priorityOrig = priority
#       if priority < 0 or priority >= size
#         priority = (size - 1)
        
#         # put obj at the end of the line
#         console.error "invalid priority: " + priorityOrig + " must be between 0 and " + priority
#     slots[priority].push obj
#     return

#   me.dequeue = (callback) ->
#     obj = null
#     i = undefined
#     sl = slots.length
    
#     # Clear cache for total.
#     total = null
#     i = 0
#     while i < sl
#       if slots[i].length
#         obj = slots[i].shift()
#         break
#       i += 1
#     obj

#   me


module.exports.Pool = (factory, test) ->
	me = {}
	idleTimeoutMillis = factory.idleTimeoutMillis ||3000
	reapInterval = factory.reapInterval||1000
	refreshIdle = if ('refreshIdle' in factory)then factory.refreshIdle else true
	availableObjects = []
	waitingClients = new priorityQueue()
	count =0
	removeIdleScheduled = false
	removedIdleTimer = null
	draining = false
	log = if factory.log then ((str, level)->
		if typeof factory.log == 'function'
			factory.log str, level 
		else
			console.log level+"pool"+factory.name
		) else ()->

	factory.max = parseInt factory.max, 10
	factory.min = parseInt factory.min, 10

	factory.max = Math.max (if isNaN factory.max then 1 else  factory.max), 1
	factory.min = Math.min (if isNaN factory.min then 0 else factory.min) , factory.max-1
 
	me.acquire = (callback, priority)->
		if draining
			throw new Error "pool is draining error"
			
		else
			waitingClients.enqueue callback, priority
			dispense()
			count < factory.max

	dispense = () ->
		waitingCount = waitingClients.size()
		log "dispense() clients="+waitingCount+"available="+availableObjects, "info"
		if waitingCount > 0
			if 	availableObjects.length > 0
				objTimeout = availableObjects[0]
				availableObjects.shift()
				clientCb = waitingClients.dequeue()
				clientCb null, objTimeout.obj

			if count < factory.max
				createResource()

	createResource = ()->
		console.log factory.create.toString()
		count+=1
		clientCb = waitingClients.dequeue()
		factory.create (err, client)->
			if(err)
				console.log "createResource error"
				count-=1
				if clientCb
					clientCb err, null
				else
					process.nextTick ()->
						dispense()
			else 
				if clientCb 
					return clientCb null, client
				else 
					me.release client

	ensureMinimum =()->
			while count < factory.min
        createResource()

	me.release = (obj) ->
		if(availableObjects.some (objWithTimeout)->
			return objWithTimeout == obj)
			return log "obj:"+obj+"has been released"

		else
			objWithTimeout = { obj: obj, timeout: new Date().getTime()+idleTimeoutMillis}
			availableObjects.push objWithTimeout
			dispense()

			scheduleRemoveIdle()

	scheduleRemoveIdle =()->
			if(!removeIdleScheduled)
				removeIdleScheduled = true
				setTimeout removeIdle, idleTimeoutMillis
	
	removeIdle = ()->
		now = new Date().getTime()
		toRemove = []
		for obj in availableObjects
			if( now > obj.timeout && toRemove.length+factory.min <count)
				toRemove.push obj

		for aobj in toRemove
			me.destroy aobj.obj

		removeIdleScheduled = false
		if( availableObjects.length > 0 )
			scheduleRemoveIdle()
		else
			log  "all availableobects has been removed"  

	me.destroy =(objclient)->
		count -=1;
		availableObjects = availableObjects.filter (objWithTimeout) ->
			return objWithTimeout != objclient

		factory.destroy objclient
		ensureMinimum()

	me.execcmd = (args...) ->
		hascallback = if typeof args[args.length-1] == "function" then true else false
		if(! hascallback)
			callback = ()->
			args.push callback

		else
			callback = args[args.length-1]

		if typeof args[0] == "string" then cmd = args[0] else return callback "error has no cmd", null
		
		me.acquire (err, client)->
			# console.log client
			console.log "****||**"+err+"****||***"+client
			console.log client.toString()
			if(err)
				callback "error while acquire client", null
			else
				#console.log "the client is " + client
				# cmdcallback = ()->
				# 	console.log "cmdcallback called"
				# 	me.release client
				# 	return callback.apply null, arguments
				
				# args.shift()
				# args[args.length-1]=cmdcallback 
				# console.log cmd, "args:"+args
				# client[cmd].apply client, args
				args.shift()
				args.pop()
				# console.log cmd
				# console.log client[cmd]
				# console.log client

				client[cmd] args, (err, result)->
					me.release client
					if(err)
						callback null, result
					else
						callback err, result
	me.getCount = ()->
		count
	me.getAvailableObjects =()->
		availableObjects

	me.getWaitingClients = ()-> waitingClients

	ensureMinimum()
	return me

