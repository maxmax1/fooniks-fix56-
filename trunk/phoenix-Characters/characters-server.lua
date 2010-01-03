connection = nil;
charFields = nil;
playerTimer = { };

function displayLoadedRes( res )	
	
	if( not connection ) then
	
		connection = mysql_connect( get( "#phoenix-Base.MYSQL_HOST" ), get( "#phoenix-Base.MYSQL_USER" ), get( "#phoenix-Base.MYSQL_PASS" ), get( "#phoenix-Base.MYSQL_DB" ) );
		
		if( not connection ) then
		
			outputDebugString( "Phoenix-Characters ei saanud mysql ühendust kätte." );
			stopResource( res );
		
		else
		
			outputDebugString( "Phoenix-Characters: Mysql serveriga ühendatud." );
		
		end	
		
	end
	
end

addEventHandler( "onResourceStart", getResourceRootElement( getThisResource( ) ), displayLoadedRes );
	
function charactersRequest( )

	if( not client ) then outputChatBox( "charRequestFeil" ); return false; end
	
	local sqlId = getElementData( client, "User.userid" );
	if( not sqlId ) then
	
		kickPlayer( client, "VIGA: Sisselogimisel läks midagi sassi, proovi uusti. " );
		return false;
	
	end
	
	spawnPlayer( client, 255.7190, -41.1370, 1002.0230, -90, 14, math.random(1000, 1250) );
	setElementInterior( client, 14 );
	setElementAlpha( client, 0 );
	fadeCamera( client, true );
	
	setCameraMatrix( client, 256.7190, -42.1370, 1003.0230, 255.7190, -41.1370, 1002.0230 );
	
	local charInf = GetUserCharactersAsTable( sqlId );
	triggerClientEvent( client, "onShowCharacters", getRootElement( ), charInf, 1, false );
	
	return true;

end

addEvent( "onCharactersRequest", true );
addEventHandler( "onCharactersRequest", getRootElement(), charactersRequest );

function GetUserCharactersAsTable( sqlId )

	local query = "SELECT id, name, sex, age, model, blurLevel FROM ph_characters WHERE userid = '" .. sqlId .. "'";
	local result = mysql_query( connection, query );
	
	local tabel = { };
	
	if( result ) then
	
		local i = 1;
		
  		while true do
  		
    		local row = mysql_fetch_row( result );
    		if(not row) then break end
  			
  			tabel[i] = { };
   			tabel[i]["id"] = row[1];
   			tabel[i]["name"] = row[2];
   			tabel[i]["sex"] = row[3];
   			tabel[i]["age"] = row[4];
   			tabel[i]["model"] = row[5];
   			tabel[i]["blurLevel"] = row[6];
   			i = i+1;
	  		
		end
		
	end

	return tabel;

end

function firstSpawnHandler( selectedChar )

	if ( not client ) then return 1; end
	
	local query = "SELECT * FROM ph_characters WHERE id = '" .. selectedChar .. "'";
	local result = mysql_query( connection, query );
	
	local wantInsert = false;
	if( charFields == nil ) then charFields = { }; wantInsert = true; end
		 
	if( result ) then
		 
		for result ,row in mysql_rows( result ) do
			
  			mysql_field_seek( result, 1 );
  			
  			local playerStuff = {};
  			
  			for k,v in ipairs( row ) do
  				
    			local field = mysql_fetch_field( result );
    				
    			if (v == mysql_null()) then v = ''; end
    				
      			playerStuff[field["name"]] = v;
      			setElementData( client, "Character." .. field["name"], v, true );
      			
      			if( wantInsert ) then
      			
      				table.insert( charFields, field["name"] );
      				
      			end
    				
	  		end
	  		
	  		if( tonumber( playerStuff["health"] ) < 5 ) then playerStuff["health"] = 15; end
	  		
	  		setPedSkin( client, playerStuff["model"] );
	  		
			setElementInterior( client, 0 );
			setElementAlpha( client, 255 );
			setElementDimension( client, 0 );
			
	  		setElementPosition( client, playerStuff["posX"], playerStuff["posY"], playerStuff["posZ"] );
	  		setPedRotation( client, playerStuff["angle"] );
	  		setElementHealth( client, tonumber( playerStuff["health"] ) );
	  		setPlayerMoney( client, tonumber( playerStuff["money"] ) );
	  		setCameraTarget( client, client );
	  		
	  		triggerEvent( "onSkillsRequired", client, client );
	  		
	  		playerTimer[client] = setTimer( savePlayer, 45000, 0, client, true );
	  		
		end
		
	end

end

addEvent( "OnRequestFirstSpawn", true );
addEventHandler( "OnRequestFirstSpawn", getRootElement(), firstSpawnHandler );

addEventHandler ( "onPlayerQuit", getRootElement(), 

	function ( qType )
	
		savePlayer( thePlayer, false );
	
	end

);

function updatePlayer( thePlayer ) -- Updates player status for saving...

	if( not thePlayer ) then return false; end
	
	local x, y, z = getElementPosition( thePlayer );
	local rot = getPedRotation( thePlayer );
	local health = getElementHealth( thePlayer );
	local money = getPlayerMoney( thePlayer );
	local model = getElementModel( thePlayer );
	local blur = getPlayerBlurLevel( thePlayer );
	
	setElementData( thePlayer, "Character.posX", x );
	setElementData( thePlayer, "Character.posY", y );
	setElementData( thePlayer, "Character.posZ", z );
	setElementData( thePlayer, "Character.angle", rot );
	setElementData( thePlayer, "Character.health", health );
	setElementData( thePlayer, "Character.money", money );
	setElementData( thePlayer, "Character.model", model );
	setElementData( thePlayer, "Character.blurLevel", blur );
	
	

end

function savePlayer( thePlayer, timed )

	if( not thePlayer or not isElement ( thePlayer ) ) then
	
		if( timed ) then
		
			killTimer( playerTimer[thePlayer] );
			
		end
		return false;
		
	end
	local charId = getElementData( thePlayer, "Character.id" );
	if( not charId ) then
	
		if( timed ) then
		
			killTimer( playerTimer[thePlayer] );
			
		end
		return false;
		
	end
	
	updatePlayer( thePlayer ); -- Update before we save...
	
	-- Start query building
	local query = call( getResourceFromName ( "phoenix-Base" ), "MysqlUpdatebuild", "ph_characters");
	local added = false;
	
  	for k,v in ipairs( charFields ) do
  		
  		if( v ~= "id" and v ~= "userid" and v ~= "name" ) then
  	
  			local v2 = getElementData( thePlayer, "Character." .. v ); -- Get the current player data.  	
  			if( v2 ~= false ) then
  		
  				query = call( getResourceFromName( "phoenix-Base" ), "MysqlSetField", query, v, v2 );
  				added = true;
  			
  			end
  			
  		end
  	
  	end
  				
	if( added ) then
	
		-- Finish query.
		query = call( getResourceFromName ( "phoenix-Base" ), "UpdateFinish", query, "id", charId);
		
		local result = mysql_query( connection, query );
		if( result ~= false and result ~= nil ) then mysql_free_result( result ); end
	
	end
	
	triggerEvent( "onSkillsSave", thePlayer, thePlayer ); -- Save Skills to. :)	
	return true;

end