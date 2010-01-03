connection = nil;
oSpeeds = { };
pSeatbelt = { };
engineStarting = { };

function displayLoadedRes( res )	
	
	if( not connection ) then
	
		connection = mysql_connect( get( "#phoenix-Base.MYSQL_HOST" ), get( "#phoenix-Base.MYSQL_USER" ), get( "#phoenix-Base.MYSQL_PASS" ), get( "#phoenix-Base.MYSQL_DB" ) );
		
		if( not connection ) then
		
			outputDebugString( "Phoenix-Vehicles ei saanud mysql ühendust kätte." );
			stopResource( res );
		
		else
		
			outputDebugString( "Mysql serveriga ühendatud." );
			LoadVehicles();
		
		end	
		
	end
	
end

addEventHandler( "onResourceStart", getResourceRootElement( getThisResource( ) ), displayLoadedRes );

function LoadVehicles()	
	
	local query = "SELECT * FROM ph_vehicles";
	local result = mysql_query( connection, query );
	local added = 0;
		 
	if( result ) then
		 
		for result ,row in mysql_rows( result ) do
			
  			mysql_field_seek( result, 1 );
  			
  			local vehicleStuff = {};
  			
  			for k,v in ipairs( row ) do
  				
    			local field = mysql_fetch_field( result );
    				
    			if (v == mysql_null()) then v = ''; end
    				
      			vehicleStuff[field["name"]] = v;
    				
	  		end
	  		
	  		local newveh = createVehicle( 
	  						vehicleStuff["vModel"], 
	  						vehicleStuff["vPosXd"],
	  						vehicleStuff["vPosYd"],
	  						vehicleStuff["vPosZd"],
	  						vehicleStuff["vAngXd"], 
	  						vehicleStuff["vAngYd"],
	  						vehicleStuff["vAngZd"],
	  						vehicleStuff["vVehNumber"]);
	  						
	  		if( newveh ~= false ) then
	  		
	  			setElementData( newveh, "vehicleId", vehicleStuff["vehicleId"]);
	  			setElementData( newveh, "vType", vehicleStuff["vType"]);
	  			setElementData( newveh, "vOwner", vehicleStuff["vOwner"]);
	  			setElementData( newveh, "vValue", vehicleStuff["vValue"]);
	  			setElementData( newveh, "vDeaths", vehicleStuff["vDeaths"]);
	  			
	  			setVehicleColor( newveh, vehicleStuff["vColor1"], vehicleStuff["vColor2"], vehicleStuff["vColor3"], vehicleStuff["vColor4"] );
	  			setElementHealth( newveh, vehicleStuff["vHealth"] );
	  			added = added + 1;
	  		
	  		end
	  		
	  			
		end
		
	end
	
	if( added == 0 ) then
	
		outputDebugString( "Phoenix-Vehicles ei suutnud ühtegi autot laadida." );
		
	else
	
		outputDebugString( "Phoenix-Vehicles laadis " .. added .. " autot." );
		setTimer( UpdateVehicleVelForCrash, 3000, 0 );
	
	end

end

function ResourceStop ()

    SaveVehicles();
    
end
addEventHandler ( "onResourceStop", getResourceRootElement ( getThisResource () ), ResourceStop, true )

function SaveVehicles()

	local arr = getElementsByType( "vehicle" );
	
	for k,v in ipairs(arr) do
	
		UpdateVehicle( v );
	
	end
	
end

function UpdateVehicle( v )

	local sqlId = getElementData( v, "vehicleId" );
	if( sqlId == false) then return false; end
	
	local col1, col2, col3, col4 = getVehicleColor ( v );
		
	-- Start query building
	local query = call( getResourceFromName ( "phoenix-Base" ), "MysqlUpdatebuild", "ph_Vehicles");
	
	-- Set Fields
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vHealth", getElementHealth( v ) );
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vColor1", col1 );
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vColor2", col2 );
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vColor3", col3 );
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vColor4", col4 );
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vOwner", getElementData( v, "vOwner" ) );
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vValue", getElementData( v, "vValue" ) );
	query = call( getResourceFromName ( "phoenix-Base" ), "MysqlSetField", query, "vDeaths", getElementData( v, "vDeaths" ) );
	
	-- Finish query.
	query = call( getResourceFromName ( "phoenix-Base" ), "UpdateFinish", query, "vehicleId", sqlId);
	
	local result = mysql_query( connection, query );
	if( result ~= false ) then mysql_free_result( result ); end
	
	return true;

end

function onVehicleRespawn ( exploded )

	if ( not exploded ) then return false; end
	
	local deaths = getElementData( v, "vDeaths" );
	
	if( deaths ~= false ) then
	
		deaths = deaths + 1;
		setElementData( newveh, "vDeaths", deaths);
	
	end

end
addEventHandler ( "onVehicleRespawn", getRootElement(), onVehicleRespawn )

function displayVehicleLoss(loss)
	
	local id = getElementData( source, "vehicleId" );
    if( not id ) then return false end
	
	local nextSeat = 0;
	local maxSeats = getVehicleMaxPassengers( source );
	local thePlayer = getVehicleOccupant(source, nextSeat);
	
	if( thePlayer ~= false ) then 
	
    	setVehicleTurnVelocity( source, 0, 0, 0.001 );
    	
    end   
	
	while ( thePlayer ~= false ) do
		
    	
    	if( loss > 50 and pSeatbelt[thePlayer] ~= nil and pSeatbelt[thePlayer] == true ) then
    	
    		removePedFromVehicle( thePlayer );
    		setTimer( setElementVelocity, 300, 1, thePlayer, oSpeeds[source][1], oSpeeds[source][2],oSpeeds[source][3] );
			
		end
    	
    	
    	nextSeat = nextSeat + 1;
    	if(nextSeat >= maxSeats) then break end
    	thePlayer = getVehicleOccupant(source, nextSeat);
    
    end
    
end
 
addEventHandler("onVehicleDamage", getRootElement(), displayVehicleLoss)

function UpdateVehicleVelForCrash(  )

	for k, v in ipairs( getElementsByType( "vehicle" ) ) do

		if( getVehicleOccupant( v ) ~= false ) then
	
			if( oSpeeds[v] == nil ) then
			
				oSpeeds[v] = { };
				
			end
	
			oSpeeds[v][1], oSpeeds[v][2],oSpeeds[v][3] = getElementVelocity( v );
	
		end

	
	end

end

function canPlayerStartVehicle( thePlayer, theVehicle )
    
	local vType = getElementData( theVehicle, "vType" );    
    local vOwner = getElementData( theVehicle, "vOwner" );
    
    if( not vType ) then vType = 0; else vType = tonumber(vType); end
    if( not vOwner ) then vOwner = 0; else vOwner = tonumber(vOwner); end 
    
    local pGroup = 0;
    local pJob = getElementData( thePlayer, "Character.playerJob" );
    local pId = getElementData( thePlayer, "Character.id" );
    local pAdmin = getElementData( thePlayer, "Character.adminLevel" );

    if( vType == 0 ) then -- Group Vehicle
    
    	if( vOwner == 0 ) then
    	
    		return true; 
    		
    	elseif( vOwner ~= pGroup ) then
    	
    		return false;
    		
    	end
    
    elseif( vType == 1 ) then -- Job Vehicle
    
    	if( vOwner == 0 ) then
    	
    		return true; 
    		
    	elseif( vOwner ~= pJob ) then
    	
    		return false;
    		
    	end
    
    elseif( vType == 2 ) then -- Buyable Vehicle
    
    	if( vOwner == 0 ) then -- OnSale
    	
    		outputChatBox( thePlayer, "See auto on müügis." );
    		return false;
    		
    	elseif( vOwner > 0 and vOwner ~= pId) then
    	
    		return false;
    		
    	else
    	
    		return true;
    	
    	end
    
    else
    
	    if( not pAdmin or pAdmin < 1 ) then return false; 
	    else return true;  end
    
    end
    
    return false;
    
end

function toggleVehicleEngine ( player, key, keyState )

	if( keyState ~= "up" ) then return 1; end

	local theVehicle = getPedOccupiedVehicle( player );
	if( not theVehicle ) then return 2; end
	
	local vType = getElementData( theVehicle, "vType" );
    if( not vType ) then
    	
    	setVehicleEngineState( theVehicle, true );
    	return 3;
    
    end
    
    if( canPlayerStartVehicle( player, theVehicle ) == false ) then
    
    	outputChatBox( "Sul pole selle masina võtmeid", player );
    
    else
	
		if( engineStarting[theVehicle] == true ) then
		
			return false;
		
		end
	
		local oldState = getVehicleEngineState ( theVehicle );
		-- 
		if( oldState == false ) then
	
			local x, y, z = getElementPosition( theVehicle );
			local colShape = createColSphere( x, y, z, 25.0 );
	
			for k,v in ipairs( getElementsWithinColShape( colShape, "player" ) ) do
	
				triggerClientEvent( v, "onVehicleStart", getRootElement( ), theVehicle );
				
			end
			
			destroyElement( colShape );
			setTimer( engineStartEnd, 3000, 1, player, theVehicle );
			setPedFrozen( player, true );
			engineStarting[theVehicle] = true;
		
		else
		
			setVehicleEngineState( theVehicle, false );
		
		end
		
		return 0;
		
	end
    
end

function engineStartEnd( thePlayer, theVehicle )

	engineStarting[theVehicle] = false;
	setPedFrozen( thePlayer, false );
	setVehicleEngineState( theVehicle, true );

end


function toggleVehicleLights ( player, key, keyState )

	local theVehicle = getPedOccupiedVehicle( player );
	if( not theVehicle or not isElement ( theVehicle )  ) then return 1; end
	
	local newState = getVehicleOverrideLights( theVehicle );
	
	if( newState == 1 ) then -- lights off
	
		newState = 2;
		
	else
	
		newState = 1;
	
	end
	
	setVehicleOverrideLights( theVehicle, newState );
    
end


function toggleVehicleSeatBelt ( player, key, keyState )

	local theVehicle = getPedOccupiedVehicle( player );
	if( not theVehicle or not isElement ( theVehicle )  ) then return 1; end
	
	pSeatbelt[player] = not pSeatbelt[player];
	
	local action = "v6tab turvav88 2ra.";
	if( pSeatbelt[player] == true ) then
	
		action = "paneb turvav88 peale.";
		
	end	
	executeCommandHandler ( "me", player, action );
    
end

function onDriverExit( thePlayer )

	if(not thePlayer or not isElement ( thePlayer ) ) then return false end
	unbindKey( thePlayer, "g", "up", toggleVehicleEngine );
	unbindKey( thePlayer, "l", "up", toggleVehicleLights );

end

addEventHandler ( "onVehicleEnter", getRootElement(),

	function ( thePlayer, seat, jacked )
	
		if( seat == 0) then
				
			
			setVehicleEngineState( source, false ); -- Someday remove this.
			setVehicleOverrideLights( source, 1 ); -- Someday remove this.
			
			bindKey( thePlayer, "g", "up", toggleVehicleEngine );
			bindKey( thePlayer, "l", "up", toggleVehicleLights );
			
		end
		
		pSeatbelt[thePlayer] = false;
		bindKey( thePlayer, "h", "up", toggleVehicleSeatBelt );
	
	end

);

addEventHandler ( "onVehicleExit", getRootElement(),

	function ( hePlayer, seat, jacked )
	
		unbindKey( thePlayer, "h", "up", toggleVehicleSeatBelt );
	
	end

);


	

