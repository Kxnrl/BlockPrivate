<?

/******************************************************************/
/*                                                                */
/*                         Block Private                          */
/*                                                                */
/*                                                                */
/*  File:          check.php                                      */
/*  Description:   block player who is private profiles.          */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle   https://kxnrl.com                  */
/*  2018/03/17 16:41:55                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/

header('Content-Type: text/html; charset=utf-8');

$api_key = "";

$url = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$api_key&steamids=".$_GET['steam'];

$curl = curl_init();
curl_setopt($curl, CURLOPT_URL, $url);
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curl, CURLOPT_HEADER, 0);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
//curl_setopt($curl, CURLOPT_PROXY, "127.0.0.1:1080");
//curl_setopt($curl, CURLOPT_PROXYTYPE, CURLPROXY_SOCKS5);
$data = curl_exec($curl);
curl_close($curl);


if(curl_errno($curl))
{
    echo 'curl error: '.curl_error($curl);
	die(200);
}

$array = json_decode($data, true);
if($array['response']['players'][0]['profilestate'] != 1 || $array['response']['players'][0]['communityvisibilitystate'] != 3)
{
	echo 'Private Profiles';
	die(200);
}

$url = "https://api.steampowered.com/ISteamUser/GetFriendList/v1/?key=$api_key&steamid=".$_GET['steam'];
$curl = curl_init();
curl_setopt($curl, CURLOPT_URL, $url);
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curl, CURLOPT_HEADER, 0);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
//curl_setopt($curl, CURLOPT_PROXY, "127.0.0.1:1080");
//curl_setopt($curl, CURLOPT_PROXYTYPE, CURLPROXY_SOCKS5);
$data = curl_exec($curl);
curl_close($curl);

if(curl_errno($curl))
{
    echo 'curl error: '.curl_error($curl);
	die(200);
}

$array = json_decode($data, true);
foreach($array as $key => $value)
{
	foreach($value['friends'] as $k => $v)
	{
		if($v['steamid'] == '76561198293577472')
		{
			echo '您的好友列表中存在[叁生鉐]';
			die(200);
		}
	}
}

echo 'Allow';

?>