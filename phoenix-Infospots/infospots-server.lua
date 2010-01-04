interiors = { };
infoSpots = { };

function displayLoadedRes( res )	

	RegisterInteriors( );
	
	-- Add some default infospots.
	addInfoSpot( "PIGPEN", "PIG PEN", 2421.3535, -1220.4412, 26.4849, 0, 10, 0 );
	addInfoSpot( "PIGPE2N", "PIG PEN", 2425.3535, -1220.4412, 26.4849, 0, 2, 0 );

end

addEventHandler( "onResourceStart", getResourceRootElement( getThisResource( ) ), displayLoadedRes );

function RegisterInteriors( )

	local xmlFile =  xmlLoadFile ( "interiors.xml" );
	if ( xmlFile ~= false ) then
	
		outputDebugString( "phoenix-Infospots: Interiors database loaded." );
	
		local allInts = xmlNodeGetChildren( xmlFile );
		
		if( allInts ~= false ) then
		
			for i, node in ipairs(allInts) do
		
           		-- node
            	local id = tonumber( xmlNodeGetAttribute( node, "id" ) );
            	
            	if( id ~= false and id ~= nil ) then
            	
            		
            		interiors[id] = { };
            	
            		interiors[id]["name"] = xmlNodeGetAttribute( node, "name" );
            		interiors[id]["sampInt"] = tonumber( xmlNodeGetAttribute( node, "sampInt" ) );
            		interiors[id]["posX"] = tonumber( xmlNodeGetAttribute( node, "posX" ) );
            		interiors[id]["posY"] = tonumber( xmlNodeGetAttribute( node, "posY" ) );
            		interiors[id]["posZ"] = tonumber( xmlNodeGetAttribute( node, "posZ" ) );
            		interiors[id]["rot"] = tonumber( xmlNodeGetAttribute( node, "rot" ) );
            		
            		outputDebugString( "Registred Interior: " .. id .. type(id) );
            	
            	end
            
      		end
      		
      	else
      	
      		outputDebugString( "phoenix-Infospots: Bad Interiors Database syntax.", 1 );
      		      
       	end

		xmlUnloadFile ( xmlFile );
		
	else
	
		outputDebugString( "phoenix-Infospots: Interiors database failed to load.", 1 );
		
	end

end

function warpToInterior( thePlayer, theInt )

	if( type( interiors[theInt] ) ~= "table" ) then
	
		outputChatBox( type( theInt ) );
		outputChatBox( #interiors );	
		return 0;
	
	end
	
	if( not thePlayer or not isElement ( thePlayer )  ) then return -1; end
	
	setElementInterior( thePlayer, interiors[theInt]["sampInt"] );
	setElementPosition( thePlayer, interiors[theInt]["posX"], interiors[theInt]["posY"], interiors[theInt]["posZ"] );
	setPedRotation( thePlayer, interiors[theInt]["rot"] );	
	
	return theInt;

end

function addInfoSpot( id, infoText, x, y, z, fromDimension, toDimension, toScriptinterior, rot )

	if( infoSpots[id] ~= nil ) then
	
		return false;
	
	end
	
	infoSpots[id]  = { };
	
	infoSpots[id]["marker"] = createMarker( x, y, z, "arrow", 2.0, 255, 255, 0 );
	setElementDimension( infoSpots[id]["marker"], fromDimension );
	setElementData( infoSpots[id]["marker"], "infoId", id );
	
	infoSpots[id]["infoText"] = infoText;
	infoSpots[id]["x"] = x;
	infoSpots[id]["y"] = y;
	infoSpots[id]["z"] = z;
	infoSpots[id]["rot"] = rot;
	infoSpots[id]["fromDimension"] = fromDimension;
	infoSpots[id]["toScriptinterior"] = toScriptinterior;
	infoSpots[id]["toDimension"] = toDimension;
	
	return true;

end



addEventHandler( "onPlayerMarkerHit", getRootElement( ),

	function ( markerHit, matchingDimension )
	
		if( matchingDimension ) then
		
			local id = getElementData( markerHit, "infoId" );
		
			if( id ~= false ) then
			
				local ret = warpToInterior( source, infoSpots[id]["toScriptinterior"] );
			
				if( ret > 0 ) then
				
					setElementDimension( source, infoSpots[id]["toDimension"] );
					setElementData( source, "Character.interior", id );
					
				end
			
			end
		
		end
	
	end

);