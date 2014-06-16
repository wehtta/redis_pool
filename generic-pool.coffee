PriorityQueue = (size) ->
  me = {}
  slots = undefined
  i = undefined
  total = null
  
  # initialize arrays to hold queue elements
  size = Math.max(+size | 0, 1)
  slots = []
  i = 0
  while i < size
    slots.push []
    i += 1
  
  #  Public methods
  me.size = ->
    i = undefined
    if total is null
      total = 0
      i = 0
      while i < size
        total += slots[i].length
        i += 1
    total

  me.enqueue = (obj, priority) ->
    priorityOrig = undefined
    
    # Convert to integer with a default value of 0.
    priority = priority and +priority | 0 or 0
    
    # Clear cache for total.
    total = null
    if priority
      priorityOrig = priority
      if priority < 0 or priority >= size
        priority = (size - 1)
        
        # put obj at the end of the line
        console.error "invalid priority: " + priorityOrig + " must be between 0 and " + priority
    slots[priority].push obj
    return

  me.dequeue = (callback) ->
    obj = null
    i = undefined
    sl = slots.length
    
    # Clear cache for total.
    total = null
    i = 0
    while i < sl
      if slots[i].length
        obj = slots[i].shift()
        break
      i += 1
    obj

  me


###
Generate an Object pool with a specified `factory`.

@param {Object} factory
Factory to be used for generating and destorying the items.
@param {String} factory.name
Name of the factory. Serves only logging purposes.
@param {Function} factory.create
Should create the item to be acquired,
and call it's first callback argument with the generated item as it's argument.
@param {Function} factory.destroy
Should gently close any resources that the item is using.
Called before the items is destroyed.
@param {Function} factory.validate
Should return true if connection is still valid and false
If it should be removed from pool. Called before item is
acquired from pool.
@param {Number} factory.max
Maximum number of items that can exist at the same time.  Default: 1.
Any further acquire requests will be pushed to the waiting list.
@param {Number} factory.min
Minimum number of items in pool (including in-use). Default: 0.
When the pool is created, or a resource destroyed, this minimum will
be checked. If the pool resource count is below the minimum, a new
resource will be created and added to the pool.
@param {Number} factory.idleTimeoutMillis
Delay in milliseconds after the idle items in the pool will be destroyed.
And idle item is that is not acquired yet. Waiting items doesn't count here.
@param {Number} factory.reapIntervalMillis
Cleanup is scheduled in every `factory.reapIntervalMillis` milliseconds.
@param {Boolean|Function} factory.log
Whether the pool should log activity. If function is specified,
that will be used instead. The function expects the arguments msg, loglevel
@param {Number} factory.priorityRange
The range from 1 to be treated as a valid priority
@param {RefreshIdle} factory.refreshIdle
Should idle resources be destroyed and recreated every idleTimeoutMillis? Default: true.
@returns {Object} An Object pool that works with the supplied `factory`.
###
exports.Pool = (factory) ->
  
  # Prepare a logger function.
  
  #/////////////
  
  ###
  Request the client to be destroyed. The factory's destroy handler
  will also be called.
  
  This should be called within an acquire() block as an alternative to release().
  
  @param {Object} obj
  The acquired item to be destoyed.
  ###
  
  ###
  Checks and removes the available (idle) clients that have timed out.
  ###
  removeIdle = ->
    toRemove = []
    now = new Date().getTime()
    i = undefined
    al = undefined
    tr = undefined
    timeout = undefined
    removeIdleScheduled = false
    
    # Go through the available (idle) items,
    # check if they have timed out
    i = 0
    al = availableObjects.length

    while i < al and (refreshIdle or (count - factory.min > toRemove.length))
      timeout = availableObjects[i].timeout
      if now >= timeout
        
        # Client timed out, so destroy it.
        log "removeIdle() destroying obj - now:" + now + " timeout:" + timeout, "verbose"
        toRemove.push availableObjects[i].obj
      i += 1
    i = 0
    tr = toRemove.length

    while i < tr
      me.destroy toRemove[i]
      i += 1
    
    # Replace the available items with the ones to keep.
    al = availableObjects.length
    if al > 0
      log "availableObjects.length=" + al, "verbose"
      scheduleRemoveIdle()
    else
      log "removeIdle() all objects removed", "verbose"
    return
  
  ###
  Schedule removal of idle items in the pool.
  
  More schedules cannot run concurrently.
  ###
  scheduleRemoveIdle = ->
    unless removeIdleScheduled
      removeIdleScheduled = true
      removeIdleTimer = setTimeout(removeIdle, reapInterval)
    return
  
  ###
  Handle callbacks with either the [obj] or [err, obj] arguments in an
  adaptive manner. Uses the `cb.length` property to determine the number
  of arguments expected by `cb`.
  ###
  adjustCallback = (cb, err, obj) ->
    return  unless cb
    if cb.length <= 1
      cb obj
    else
      cb err, obj
    return
  
  ###
  Try to get a new client to work, and clean up pool unused (idle) items.
  
  - If there are available clients waiting, shift the first one out (LIFO),
  and call its callback.
  - If there are no waiting clients, try to create one if it won't exceed
  the maximum number of clients.
  - If creating a new client would exceed the maximum, add the client to
  the wait list.
  ###
  dispense = ->
    obj = null
    objWithTimeout = null
    err = null
    clientCb = null
    waitingCount = waitingClients.size()
    log "dispense() clients=" + waitingCount + " available=" + availableObjects.length, "info"
    if waitingCount > 0
      while availableObjects.length > 0
        log "dispense() - reusing obj", "verbose"
        objWithTimeout = availableObjects[0]
        unless factory.validate(objWithTimeout.obj)
          me.destroy objWithTimeout.obj
          continue
        availableObjects.shift()
        clientCb = waitingClients.dequeue()
        return clientCb(err, objWithTimeout.obj)
      createResource()  if count < factory.max
    return
  createResource = ->
    count += 1
    log "createResource() - creating obj - count=" + count + " min=" + factory.min + " max=" + factory.max, "verbose"
    factory.create ->
      err = undefined
      obj = undefined
      clientCb = waitingClients.dequeue()
      console.log clientCb
      console.log arguments_
      if arguments_.length > 1
        err = arguments_[0]
        obj = arguments_[1]
      else
        err = (if (arguments_[0] instanceof Error) then arguments_[0] else null)
        obj = (if (arguments_[0] instanceof Error) then null else arguments_[0])
      if err
        count -= 1
        clientCb err, obj  if clientCb
        process.nextTick ->
          dispense()
          return

      else
        if clientCb
          
          # console.log("successful create client");
          clientCb err, obj
        else
          me.release obj
      return

    return
  ensureMinimum = ->
    i = undefined
    diff = undefined
    if not draining and (count < factory.min)
      diff = factory.min - count
      i = 0
      while i < diff
        createResource()
        i++
    return
  me = {}
  idleTimeoutMillis = factory.idleTimeoutMillis or 30000
  reapInterval = factory.reapIntervalMillis or 1000
  refreshIdle = (if ("refreshIdle" of factory) then factory.refreshIdle else true)
  availableObjects = []
  waitingClients = new PriorityQueue(factory.priorityRange or 1)
  count = 0
  removeIdleScheduled = false
  removeIdleTimer = null
  draining = false
  log = (if factory.log then ((str, level) ->
    if typeof factory.log is "function"
      factory.log str, level
    else
      console.log level.toUpperCase() + " pool " + factory.name + " - " + str
    return
  ) else ->
  )
  factory.validate = factory.validate or ->
    true

  factory.max = parseInt(factory.max, 10)
  factory.min = parseInt(factory.min, 10)
  factory.max = Math.max((if isNaN(factory.max) then 1 else factory.max), 1)
  factory.min = Math.min((if isNaN(factory.min) then 0 else factory.min), factory.max - 1)
  me.destroy = (obj) ->
    count -= 1
    availableObjects = availableObjects.filter((objWithTimeout) ->
      objWithTimeout.obj isnt obj
    )
    factory.destroy obj
    ensureMinimum()
    return

  
  ###
  Request a new client. The callback will be called,
  when a new client will be availabe, passing the client to it.
  
  @param {Function} callback
  Callback function to be called after the acquire is successful.
  The function will receive the acquired item as the first parameter.
  
  @param {Number} priority
  Optional.  Integer between 0 and (priorityRange - 1).  Specifies the priority
  of the caller if there are no available resources.  Lower numbers mean higher
  priority.
  
  @returns {Object} `true` if the pool is not fully utilized, `false` otherwise.
  ###
  me.acquire = (callback, priority) ->
    throw new Error("pool is draining and cannot accept work")  if draining
    waitingClients.enqueue callback, priority
    dispense()
    count < factory.max

  me.borrow = (callback, priority) ->
    log "borrow() is deprecated. use acquire() instead", "warn"
    me.acquire callback, priority
    return

  
  ###
  Return the client to the pool, in case it is no longer required.
  
  @param {Object} obj
  The acquired object to be put back to the pool.
  ###
  me.release = (obj) ->
    
    # check to see if this object has already been released (i.e., is back in the pool of availableObjects)
    if availableObjects.some((objWithTimeout) ->
      objWithTimeout.obj is obj
    )
      log "release called twice for the same resource: " + (new Error().stack), "error"
      return
    
    #log("return to pool");
    objWithTimeout =
      obj: obj
      timeout: (new Date().getTime() + idleTimeoutMillis)

    availableObjects.push objWithTimeout
    log "timeout: " + objWithTimeout.timeout, "verbose"
    dispense()
    scheduleRemoveIdle()
    return

  me.returnToPool = (obj) ->
    log "returnToPool() is deprecated. use release() instead", "warn"
    me.release obj
    return

  
  ###
  Disallow any new requests and let the request backlog dissapate.
  
  @param {Function} callback
  Optional. Callback invoked when all work is done and all clients have been
  released.
  ###
  me.drain = (callback) ->
    log "draining", "info"
    
    # disable the ability to put more work on the queue.
    draining = true
    check = ->
      if waitingClients.size() > 0
        
        # wait until all client requests have been satisfied.
        setTimeout check, 100
      else unless availableObjects.length is count
        
        # wait until all objects have been released.
        setTimeout check, 100
      else
        callback()  if callback
      return

    check()
    return

  
  ###
  Forcibly destroys all clients regardless of timeout.  Intended to be
  invoked as part of a drain.  Does not prevent the creation of new
  clients as a result of subsequent calls to acquire.
  
  Note that if factory.min > 0, the pool will destroy all idle resources
  in the pool, but replace them with newly created resources up to the
  specified factory.min value.  If this is not desired, set factory.min
  to zero before calling destroyAllNow()
  
  @param {Function} callback
  Optional. Callback invoked after all existing clients are destroyed.
  ###
  me.destroyAllNow = (callback) ->
    log "force destroying all objects", "info"
    willDie = availableObjects
    availableObjects = []
    obj = willDie.shift()
    while obj isnt null and obj isnt `undefined`
      me.destroy obj.obj
      obj = willDie.shift()
    removeIdleScheduled = false
    clearTimeout removeIdleTimer
    callback()  if callback
    return

  
  ###
  Decorates a function to use a acquired client from the object pool when called.
  
  @param {Function} decorated
  The decorated function, accepting a client as the first argument and
  (optionally) a callback as the final argument.
  
  @param {Number} priority
  Optional.  Integer between 0 and (priorityRange - 1).  Specifies the priority
  of the caller if there are no available resources.  Lower numbers mean higher
  priority.
  ###
  me.pooled = (decorated, priority) ->
    ->
      callerArgs = arguments_
      callerCallback = callerArgs[callerArgs.length - 1]
      callerHasCallback = typeof callerCallback is "function"
      me.acquire ((err, client) ->
        if err
          callerCallback err  if callerHasCallback
          return
        args = [client].concat(Array::slice.call(callerArgs, 0, (if callerHasCallback then -1 else `undefined`)))
        args.push ->
          me.release client
          callerCallback.apply null, arguments_  if callerHasCallback
          return

        console.log "decorated: " + args
        decorated.apply null, args
        return
      ), priority
      return

  me.execcmd = (args...) ->
    hascallback = if typeof args[args.length-1] == "function" then true else false
    if(! hascallback)
      callback = ()->
      args.push callback

    else
      callback = args[args.length-1]

    if typeof args[0] == "string" then cmd = args[0] else return callback "error has no cmd", null
    
    me.acquire (err, client)->
      if(err)
        callback "error while acquire client", null
      else
        # cmdcallback = ()->
        #   console.log "cmdcallback called"
        #   me.release client
        #   return callback.apply null, arguments
        
        # args.shift()
        # args[args.length-1]=cmdcallback 
        # console.log cmd, "args:"+args
        # client[cmd].apply client, args
        args.shift()
        args.pop()
        client[cmd] args, (err, result)->
          me.release client
          if(err)
            callback null, result
          else
            callback err, result   
             
  me.getPoolSize = ->
    count

  me.getName = ->
    factory.name

  me.availableObjectsCount = ->
    availableObjects.length

  me.waitingClientsCount = ->
    waitingClients.size()

  
  # create initial resources (if factory.min > 0)
  ensureMinimum()
  me
