addEventHandler("onResourceStart", getRootElement(), --ajutine	function()					end)addCommandHandler("pr�git��", --ajutine	function(player)			setElementData(player, "Character.playerJob", "1")		outputChatBox("((Pr�givedaja t�� seatud, kasuta /pr�gi))", player)		end	)function AddTrashCan( ... )	triggerClientEvent( getRootElement( ), "onTrashCanAdd", getRootElement( ), ... );end