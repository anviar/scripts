<?php
header('Content-Type: text/html; charset=utf-8'); 

	$http_user = $_SERVER ["REMOTE_USER"];
	// get connected
	$valid_users = array (
		"makarenko_an" => array ("db"),
		"kluchkin_op" => array ("reports"),
		"kotlyarov_ds" => array ("1c")
	);
// select tbl
if (in_array ($http_user, array_keys ($valid_users))) {
	if (in_array ($_REQUEST ["tbl"], array_values ($valid_users [$http_user]))) {
		$db_table = $_REQUEST ["tbl"];
	}
	else {
		$db_table = $valid_users [$http_user][0];
	}

	$check_table = "<select size=\"1\">\n";

	foreach ($valid_users [$http_user] as $k => $v) {
		($v == $db_table) ? $sel = " selected" : $sel = "";
		$check_table .= "	<option onclick='javascript:document.location.href=\"index.php?tbl=$v\"'".  $sel .">$v</option>\n";
	}

	$check_table .= "</select>";
} else {
	$db_table = "feeds";

}

	$host   = "localhost";
	$user   = "rss";
	$passwd = "ssr";
	$dbname = "rss";
	$conn 	= mysql_connect ($host, $user, $passwd);
	mysql_select_db ($dbname);

if ($_REQUEST ["act"] == "delete" & $_REQUEST ["id"] != 0) {
	mysql_query ("delete from $db_table where id = ". $_REQUEST ["id"]);
}
// handle REQUEST request
if ($_REQUEST ["act"] == "insert") {
	$t = $_REQUEST ["Title"];
	$d = $_REQUEST ["Description"];
	$b = $_REQUEST ["Body"];

	if ($_REQUEST ["id"]) {
		$id = $_REQUEST ["id"];
		$query = sprintf ( "update $db_table set Title = '%s', Description = '%s', Body = '%s' where id = %d", mysql_real_escape_string ($t), mysql_real_escape_string ($d), ($b), $id );

		mysql_query ($query);
		$welcome_msg = "Сообщение было обновлено.";
	}
	else {
		$id = time ();		
		$query = sprintf ( "insert into $db_table (id, Title, Description, Body) values (%d, '%s', '%s', '%s')", $id, mysql_real_escape_string ($t), mysql_real_escape_string ($d),  ($b) );
		mysql_query ($query);
		$welcome_msg = "Сообщение добавлено в ленту.";
	}
}

	$actstr = "Просмотр записей";

if (($_REQUEST ["act"] == "edit") && ($_REQUEST ["id"])) {
	$rec = get_data ($db_table, $_REQUEST["id"]);
	$actstr = "Редактирование";
	$hidden = sprintf ( "<input type=\"hidden\" name=\"id\" value=\"%d\">", $_REQUEST ["id"] );
}


	$hidden .= sprintf ( "<input type=\"hidden\" name=\"tbl\" value=\"%s\">", $db_table );
?>

<!--  HEADER  -->
<html>
	<head>
		<title> RSS :: <?php echo $actstr; ?> </title>
<style type="text/css">
submit {
	display: inline;
}

tables {
	display: inline;
}
</style>
	</head>
	<body>
		<center><?php echo $welcome_msg; ?></center>


<table cellpadding="0" width="100%" cellspacing="0" border="0">
<tr>
<?php
	$res = mysql_query ("select * from $db_table order by id desc limit 20", $conn);
	
	if (in_array ($http_user, array_keys ($valid_users)) && (mysql_num_rows ($res) == 0)) {
		print "<td align=\"center\">\n";
		print "<font size=\"+1\">Записей не найдено!</font><br />\n";
		print "<img src=\"norecords.jpg\">\n";
		print "</td>";
	}
	else {
?>
	<td align="left">
<table valign="top" border="1px" style="table {bordercolor: black;}">
<?php	
?>
<tr>
	<th>Название</th>
	<th>Описание</th>
	<th>Действия</th>
</tr>
<?php
	// list of last 20 records
		while ($row = mysql_fetch_assoc ($res)) {
			print ("<tr valign=\"top\">\n");
			print ("	<td>" .substr ($row ['Title'], 0, 50). "</td>\n");
			print ("	<td>" .substr ($row ['Description'], 0, 50). "</td>\n");
			printf ("	<td>" ."<a href=\"index.php?act=edit&tbl=$db_table&id=%d\">Редактировать</a>". "<br />\n", $row ["id"]);
			printf ("	<a href=\"index.php?act=delete&tbl=$db_table&id=%d\">Удалить</a></td>\n", $row ["id"]);
print ("</tr>\n");
		}
?>
</table>
	</td>
<?php
	}
?>
	<td valign="top" align="right">

<form method="post" action="index.php?act=insert">
<table>
	<tr>
		<td>Название:</td>
		<td colspan="2"><input type="text" name="Title" size="54" value="<?php echo $rec ['Title']; ?>"></td>
	</tr>
	<tr>
		<td>Описание:</td>
		<td colspan="2"><textarea name="Description" rows="4" cols="70"><? echo $rec ['Description']; ?></textarea></td>
	</tr>
	<tr>
		<td>Текст:</td>
		<td colspan="2"><textarea name="Body" rows="6" cols="70"><?php echo $rec ['Body']; ?></textarea></td>
	</tr>
        <tr>
		<td></td>
		<td align="left"><?php echo $check_table; ?></td>
		<td align="right"><input type="submit" value = "Отправить"></td>
	</tr>
</table>
	
        <?php echo $hidden; ?>
</form>
	</td>
	</body>
</html>
<?

function get_data ($db_table, $id) {
	$res = mysql_query ("select * from $db_table where id = $id"); 
	$data = mysql_fetch_assoc ($res);
	return $data;
}
	mysql_close ($conn);
?>
