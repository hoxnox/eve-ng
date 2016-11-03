function labController($scope, $http, $location, $uibModal, $rootScope, $q, $log, $compile, $timeout, $window, $timeout, $state) {
	
	//$scope.testAUTH("/lab"); //TEST AUTH
	$('body').removeClass().addClass('skin-blue sidebar-mini sidebar-collapse');
	$('html ').css({'min-height' : '100% !important', 'height': '100%'});
	$('body').css({'min-height' : '100% !important', 'height': '100%'});
	$('.content-wrapper').css({'min-height' : '100% !important', 'height': '100%'});
	$('mainDIV').css({'min-height' : '100% !important', 'height': '100%'});
	
	contextMenuInitConn()
	contextMenuInit()
	
	//console.log()
	
	$scope.node={};
	$scope.text={};
	$scope.networks={};
	$scope.interfList={};
	$scope.interfListCount=false;
	$scope.ready=false;
	$scope.tempConn= new Object();
	$scope.changedCursor="";
	$scope.addNewObject={};
	$scope.fullPathToFile=$rootScope.lab;
	$scope.mainDivHeight = parseInt($('html').height()) - 15;
	$scope.collapseSidebar = function(){
		$('body').removeClass('sidebar-expanded-on-hover').addClass('sidebar-collapse');
	}
	
	$scope.topologyRefresh = function(){
		$scope.networkListRefresh()
		$scope.nodeListRefresh();

		for (i in $scope.node)
		{
			var node = $scope.node[i];
			if (!$("#nodeID_" + node.id))
				nodeInit(node)
		}
	}

	$scope.networkListRefresh = function(){
		$http.get('/api/labs'+$rootScope.lab+'/networks')
		.then(
			function successCallback(response){
				console.log(response);
				$scope.networks=response.data.data
			}
		)
	}
	$scope.networkListRefresh()
	
	$scope.nodeListRefresh = function(){
		$http.get('/api/labs'+$rootScope.lab+'/nodes')
		.then(
			function successCallback(response){
				console.log("nodeListRefresh:",response);
				$scope.node=response.data.data
			}
		)
	}
	$scope.nodeListRefresh()
	
	$scope.mouseOverMainDiv = function($event){
		
	}
	
	$scope.mainFieldClick = function($event,src){
		$('body').removeClass('sidebar-expanded-on-hover').addClass('sidebar-collapse');
		if (src == undefined) {$scope.addNewObject={}; $scope.addNewObject=$event}
		else {$scope.addNewObject={}; $scope.addNewObject.pageX=$('#'+src).offset().left; $scope.addNewObject.pageY=$('#'+src).offset().top;}
		
		switch ($scope.changedCursor){
			case 'node':
				$scope.changedCursor='';
				$scope.openModal('addNode');
				break;
			case 'network':
				$scope.changedCursor='';
				$scope.openModal('addNet');
				break;
			case 'text':
				$scope.changedCursor='';
				$scope.openModal('addText');
				break;
			case 'shape':
				$scope.changedCursor='';
				$scope.openModal('addShape');
				break;
			case 'image':
				$scope.changedCursor='';
				$scope.openModal('addImage');
				break;
		}
	}
	
	$scope.closeLab = function(){
		var fl = true;
		for (i in $scope.node)
		{
			if ($scope.node[i].status == 2)
				fl = false;
		}
		if (!fl){
			alert('There are running nodes, you need to power off them before closing the lab.')
		}
		else {
			$http({
				method: 'DELETE',
				url: '/api/labs/close'})
				.then(
					function successCallback(response) {
						console.log(response)
						console.log($location.url())
						blockUI();
						$window.location.hash="#/main";
						//console.log($window.location)
						$window.location.reload();
						//$location.path('/main')
					}, 
					function errorCallback(response) {
						console.log(response)
						$window.location.hash="#/main";
						$window.location.reload();
						//$location.path('/main')
					}
			);
			jsPlumb.detachEveryConnection();
		}
		//jsPlumb.reset();
		

	}
	$scope.compileNewElement = function(el, id, object){
		$('#canvas').append($compile(el)($scope))
		if (id.search('text') != -1){
			jsPlumbObjectInit($('#'+id), object)
		} else if(id.search('shape') != -1){
			jsPlumbObjectInit($('#'+id), object)
		} else {
			jsPlumbNodeInit($('#'+id))
		}
	}

	$scope.wipeAllNode = function(){
		for(i in $scope.node)
		{
			var node = $scope.node[i];
			$scope.wipeNode(node.id);
		}
	}

	$scope.wipeNode = function(id){
		if (!id)
		{
			id = $("#tempElID").val();
			id = id.replace("nodeID_", "");
		}
		$http.get('/api/labs'+$rootScope.lab+'/nodes/'+id+'/wipe')
		console.log("s-a transmis wipe")
	}

	$scope.startAllNode = function(){
		for(i in $scope.node)
		{
			var node = $scope.node[i];
			if (node.status == 0){
				$scope.startstopNode(node.id);
			}
			
		}
	}

	$scope.stopAllNode = function(){
		for(i in $scope.node)
		{
			var node = $scope.node[i];
			if (node.status == 2){
				$scope.startstopNode(node.id);
			}
			
		}
	}

	$scope.startstopNode = function(id){
		if (!id)
		{
			id = $("#tempElID").val();
			id = id.replace("nodeID_", "");
		}
		if(!$scope.node[id].upstatus){
			//START NODE //START
			$scope.node[id].loadclassShow=true;
			$http.get('/api/labs'+$rootScope.lab+'/nodes/'+id+'/start').then(
				function successCallback(response){
					$scope.node[id].upstatus=true;
					$scope.node[id].loadclassShow=false;
					$scope.node[id].status=2;
				}, function errorCallback(response){
					$scope.node[id].upstatus=false;
					$scope.node[id].loadclassShow=false;
					console.log('Server Error');
					console.log(response.data);
					toastr["error"](response.data.message, "Error");
				}
			);
			//$timeout(function () {
			//	$scope.node[id].upstatus=true;
			//	$scope.node[id].loadclassShow=false;
			//}, 4000);
			
			//START NODE //END
		} else {
			//STOP NODE //START
			$scope.node[id].loadclassShow=true;
			$http.get('/api/labs'+$rootScope.lab+'/nodes/'+id+'/stop').then(
				function successCallback(response){
					$scope.node[id].upstatus=false;
					$scope.node[id].status=0;
					$scope.node[id].loadclassShow=false;
				}, function errorCallback(response){
					$scope.node[id].upstatus=false;
					$scope.node[id].loadclassShow=false;
					console.log('Server Error');
					console.log(response.data);
					toastr["error"](response.data.message, "Error");
				}
			);
			//$timeout(function () {
			//	$scope.node[id].upstatus=false;
			//	$scope.node[id].loadclassShow=false;
			//}, 4000);
			//STOP NODE //END
		}
	}
	
	$scope.nodeClickDown=false;
	$scope.nodeDraggingFlag=false;
	$scope.nodeTouching = function(node, $event){
		//$event.preventDefault();
		$scope.nodeClickDown=true;
		//console.log($scope.nodeClickDown)
	}
	
	$scope.nodeDragging = function(node, $event){
		$event.preventDefault();
		if ($scope.nodeClickDown && !$scope.nodeDraggingFlag) $scope.nodeDraggingFlag = true;
		
		//console.log($scope.nodeDraggingFlag)
	}

	$scope.openNodeConsole = function(node, $event){
		if (!$scope.node[node].upstatus) {$event.preventDefault(); console.log('Node down console locked')}
		if ($scope.nodeDraggingFlag) {$event.preventDefault(); console.log('Node draged console locked')}
		$scope.nodeClickDown=false;
		$scope.nodeDraggingFlag=false;
	}

	$scope.textClickDown=false;
	$scope.textDraggingFlag=false;
	
	$scope.textTouching = function(textElement, $event){
		//$event.preventDefault();
		$scope.textClickDown=true;
		//console.log($scope.nodeClickDown)
	}
	
	$scope.textDragging = function(textElement, $event){
		if ($scope.textClickDown && !$scope.textDraggingFlag) $scope.textDraggingFlag = true;
	}
	
	$scope.openTextConsole = function(node, $event){
		if (!$scope.text[node].upstatus) {$event.preventDefault(); console.log('Text down console locked')}
		if ($scope.textDraggingFlag) {$event.preventDefault(); console.log('Text draged console locked')}
		$scope.textClickDown=false;
		$scope.textDraggingFlag=false;
	}
	
	$scope.shapeClickDown=false;
	$scope.shapeDraggingFlag=false;
	
	$scope.shapeTouching = function(textElement, $event){
		//$event.preventDefault();
		$scope.shapeClickDown=true;
		//console.log($scope.nodeClickDown)
	}
	
	$scope.shapeDragging = function(textElement, $event){
		if ($scope.shapeClickDown && !$scope.shapeDraggingFlag) $scope.shapeDraggingFlag = true;
	}
	
	$scope.openShapeConsole = function(node, $event){
		if (!$scope.shape[node].upstatus) {$event.preventDefault(); console.log('Shape down console locked')}
		if ($scope.shapeDraggingFlag) {$event.preventDefault(); console.log('Shape draged console locked')}
		$scope.shapeClickDown=false;
		$scope.shapeDraggingFlag=false;
	}
	

	$scope.openAllObjects = function(){
		$http.get('/api/labs'+$rootScope.lab+'/textobjects').then(
			function successCallback(response){
				console.log(response)
			}
		)
	}
	
	$scope.newConnModal = function(conn){
		if ($scope.ready){
			//console.log(conn)
			$scope.addConnSrc=conn.source
			$scope.addConnDst=conn.target
			var src = {};
			src.type = ($scope.addConnSrc.id.search('node') != -1) ? 'node' : 'network';
			var dst = {};
			dst.type = ($scope.addConnDst.id.search('node') != -1) ? 'node' : 'network';
			src.eveID = (src.type == 'node') ? $scope.addConnSrc.id.replace('nodeID_','') : '';
			dst.eveID = (dst.type == 'node') ? $scope.addConnDst.id.replace('nodeID_','') : '';
			
			jsPlumb.detach(conn)
			
			if (src.eveID != '') {if ($scope.node[src.eveID].status != 0) {toastr["error"]("Stop nodes which you want to connect", "Error"); return;} } 
			if (dst.eveID != '') {if ($scope.node[dst.eveID].status != 0) {toastr["error"]("Stop nodes which you want to connect", "Error"); return;} } 
			$scope.openModal('addConn');
			$scope.ready=false;
		}
	}
	$scope.addNewCursor = function(type){
		console.log("type", type)
		$scope.changedCursor = '';
		$('body').removeClass('sidebar-expanded-on-hover').addClass('sidebar-collapse');
		$(".openright").hide();
		setTimeout(function(){
			$(".openright").show();
		}, 100)
		switch (type) {
			case 'node':
				$scope.changedCursor = 'node';
				break;
			case 'network':
				$scope.changedCursor = 'network';
				break;
			case 'text':
				$scope.changedCursor = 'text';
				break;
			case 'shape':
				$scope.changedCursor = 'shape';
				break;
			case 'image':
				$scope.changedCursor = 'image';
				break;
			}
			
	}
	
	$scope.tempElID='';
	$scope.deleteEl = function(){
		$scope.tempElID=$('#tempElID').val()
        console.log("#tempElID:",$('#tempElID').val())
		var type = '';
		var element = '';
		if($scope.tempElID.search('node') != -1) type = 'node' 
		if($scope.tempElID.search('net') != -1) type = 'network' 
		if($scope.tempElID.search('conn') != -1) type = 'conn' 
		if($scope.tempElID.search('text') != -1) {
			type = 'textobject';
			element = 'text';
		} 
		if($scope.tempElID.search('shape') != -1) {
			type = 'textobject';
			element = 'shape';	
		} 
		// if($scope.tempElID.search('image') != -1) type = 'picture' 
		var id = $scope.tempElID.replace(element ? element + 'ID_' : type + 'ID_','');
		if (confirm('Are you sure?')){
				console.log("deteling id + type: "+ id+' '+type)
				$http({
					method: 'DELETE',
					url:'/api/labs'+$rootScope.lab+'/'+type+'s/'+id}).then(
					function successCallback(response){
						console.log(response)
						jsPlumb.select({source:type+'ID_'+id}).detach();
						jsPlumb.select({target:type+'ID_'+id}).detach();
						var selector = element ? element : type; 
						console.log($('#'+selector+'ID_'+id))
						$('#' + selector +'ID_'+id).remove()
					}, function errorCallback(response){
						console.log('Server Error');
						console.log(response);
					}
				);
		}
	}
	$scope.editEl = function(){
		$scope.tempElID=$('#tempElID').val()
		var type = ($scope.tempElID.search('node') != -1) ? 'node' : 'network';
		var id = (type == 'node') ? $scope.tempElID.replace('nodeID_','') : $scope.tempElID.replace('networkID_','');
		$scope.tempEldata = {
			'type': type,
			'id': id
		}
		if (type === 'node'){
			console.log('Open edit node modal')
			$scope.openModal('editNode');
		}
		if (type === 'network'){
			console.log('Open edit network modal')
			$scope.openModal('editNet');
		}
	}
	
	$scope.delConn = function(conn){
		var ifs = {}
		var src = {}
		var dst = {}
		src.type = (conn.source.id.search('node') != -1) ? 'node' : 'network';
		dst.type = (conn.target.id.search('node') != -1) ? 'node' : 'network';
		src.id = (src.type == 'node') ? conn.source.id.replace('nodeID_','') : conn.source.id.replace('networkID_','');
		dst.id = (dst.type == 'node') ? conn.target.id.replace('nodeID_','') : conn.target.id.replace('networkID_','');
		var urlCalls = [];
		ifs = conn.getParameters()
		console.log(ifs)
		if (ifs.type == 'ethernet'){
		if (src.type == 'node' && dst.type == 'node'){
			$scope.getIntrfInfo(src.id).then(function(something){
				console.log(something)
				//console.log(conn.getParameters())
				var network_id = "";
				var finalPrepare = {}
				var tempObj = {}
				for (var key in something.ethernet){
					if (something.ethernet[key].name==ifs.interfSrc) {
						network_id=something.ethernet[key].network_id;
					}
				}
				for (var key in something.serial){
					var tempsrl=something.serial[key].remote_id+':'+something.serial[key].remote_if
					tempObj[key]=(tempsrl == "0:0")? '' : String(tempsrl);
					jQuery.extend(finalPrepare, tempObj)
				}
				console.log(network_id)
				if (network_id !== '') {
					$http.delete('/api/labs'+$rootScope.lab+'/networks/'+network_id)
					.then(
					function successCallback(response){
						console.log(response)
						jsPlumb.detach(conn);
					}, function errorCallback(response){
						console.log('Server Error');
						console.log(response);
					}
					)
				}
			})
			
			return;
		} else {
			$scope.getIntrfInfo(src.id).then(function(something){
				ifs = conn.getParameters()
				var finalPrepare = {}
				var tempObj = {}
				for (var key in something.ethernet){
					if (something.ethernet[key].name==ifs.interfSrc) {something.ethernet[key].network_id="";
						tempObj[''+key+'']=String(something.ethernet[key].network_id)
						jQuery.extend(finalPrepare, tempObj)
					}
				}
				for (var key in something.serial){
					var tempsrl=something.serial[key].remote_id+':'+something.serial[key].remote_if
					tempObj[key]=(tempsrl == "0:0")? '' : String(tempsrl);
					jQuery.extend(finalPrepare, tempObj)
				}
				
				console.log(finalPrepare)
				$http({
					method: 'PUT',
					url:'/api/labs'+$rootScope.lab+'/nodes/'+src.id+'/interfaces',
					data: finalPrepare}).then(
					function successCallback(response){
						console.log(response)
						jsPlumb.detach(conn);
						//$scope.interfList = response.data.data;
					}, function errorCallback(response){
						console.log('Server Error');
						console.log(response);
					}
				);
				//console.log($scope.node[src.id].ifList)
			})
		}
		} else if (ifs.type == 'serial'){
			console.log('delete serial connection')
			$scope.getIntrfInfo(src.id).then(function(something){
				var finalPrepare = {}
				var tempObj = {}
				for (var key in something.ethernet){
						tempObj[''+key+'']=(something.ethernet[key].network_id == 0) ? '' : String(something.ethernet[key].network_id)
						jQuery.extend(finalPrepare, tempObj)
				}
				for (var key in something.serial){
					if (something.serial[key].name != ifs.interfSrc){
						var tempsrl=something.serial[key].remote_id+':'+something.serial[key].remote_if
						tempObj[key]=(tempsrl == "0:0")? '' : String(tempsrl);
						jQuery.extend(finalPrepare, tempObj)
					} else {
						tempObj[key]="";
						jQuery.extend(finalPrepare, tempObj)
					}
				}
				console.log(finalPrepare)
				console.log(something)
				$http({
					method: 'PUT',
					url:'/api/labs'+$rootScope.lab+'/nodes/'+src.id+'/interfaces',
					data: finalPrepare}).then(
					function successCallback(response){
						console.log(response)
						jsPlumb.detach(conn);
						//$scope.interfList = response.data.data;
					}, function errorCallback(response){
						console.log('Server Error');
						console.log(response);
					}
				);
				//console.log($scope.node[src.id].ifList)
			})
		}
	}
	
	$scope.getIntrfInfo = function(id){
		var deferred = $q.defer();
		$scope.interfList={};
		$scope.interfListCount=true;
		$http.get('/api/labs'+$rootScope.lab+'/nodes/'+id+'/interfaces').then(
			function successCallback(response){
				//console.log(response)
				$scope.interfList = response.data.data;
				deferred.resolve(response.data.data)
				$scope.node[id].ifList = response.data.data;
				$scope.interfListCount=false;
			}, function errorCallback(response){
				$scope.interfListCount=false;
				deferred.reject('Error')
				console.log('Server Error');
				console.log(response.data);
			}
		);
		return deferred.promise;
	}
	
	$scope.setPosition = function(top,left,id,type,object){
		var sendingData = {};
		if(type == 'text'){
			type = 'textobject';
			id = id.substr(7); // 7 == "textID_".length
			if(object.data && typeof(object.data) == "string"){
				object.data = JSON.parse(new TextDecoderLite('utf-8').decode(toByteArray(object.data)));
			}
			object.data.left = left;
			object.data.top  = top;
			sendingData = object;
			sendingData.data = fromByteArray(new TextEncoderLite('utf-8').encode(JSON.stringify(object.data)));
		} if(type == 'shape'){
			type = 'textobject';
			id = id.substr(8); // 8 == "shapeID_".length
			if(object.data && typeof(object.data) == "string"){
				object.data = JSON.parse(new TextDecoderLite('utf-8').decode(toByteArray(object.data)));
			}
			object.data.left = left;
			object.data.top  = top;
			sendingData = object;
			sendingData.data = fromByteArray(new TextEncoderLite('utf-8').encode(JSON.stringify(object.data)));
		} else {
			sendingData = {'left':left, 'top':top }
		}
		$http({
			method: 'PUT',
			url:'/api/labs'+$rootScope.lab+'/'+type+'s/'+id,
			data: sendingData}).then(
			function successCallback(response){
				//console.log(response)
				console.log('Position of '+type+' with id '+id+' saved')
				jsPlumb.repaintEverything();
				//$scope.interfList = response.data.data;
			}, function errorCallback(response){
				console.log('setPosition: [Server Error]');
				console.log(response);
			}
		);
	}
	///////////////////////////////
	//More controllers //START
	ModalCtrl($scope, $uibModal, $log, $rootScope, $http,$window)
	//sidebarCtrl($scope)
	//More controllers //END
	//Escape from all//START
	function escapefunction() {
		window.onkeyup = function(e) {
			if ( e.keyCode === 27 ) {
				$scope.addNewObject={};
				console.log('Esc')
				$('body').removeClass('sidebar-expanded-on-hover').addClass('sidebar-collapse');
				
				if ($scope.changedCursor) $scope.changedCursor = '';

				$('#mainDIV').removeClass("router-cursor").removeClass("network-cursor");
				$('.treeview').addClass("openright");
				$state.reload;
			}
		}
	}
	escapefunction();
	//Escape from all//END
}

function ObjectLength( object ) {
    var length = 0;
    for( var key in object ) {
        if( object.hasOwnProperty(key) ) {
            ++length;
        }
    }
	return length;
}