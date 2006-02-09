Attribute VB_Name = "mod_help"
'ignitionServer is (C)  Keith Gable and Nigel Jones.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@silentsoft.net>
'                     Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
'This program is free software.
'You can redistribute it and/or modify it under the terms of the
'GNU General Public License as published by the Free Software Foundation; either version 2 of the License,
'or (at your option) any later version.
'
'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
'Without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
'See the GNU General Public License for more details.
'
'You should have received a copy of the GNU General Public License along with this program.
'if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Public hlp As Help

Public Type Help

Oper As String: OperSyntax As String: OperExample As String
Nick As String: NickSyntax As String: NickExample As String
Who As String: WhoSyntax As String: WhoExample As String
GNotice As String: GNoticeSyntax As String: GNoticeExample As String

End Type


'/*
'** m_help
'*/
Public Function m_help(cptr As clsClient, sptr As clsClient, helpcmd As String) As Long
#If Debugging = 1 Then
    SendSvrMsg "HELP called! (" & cptr.Nick & ")"
#End If

'General Commands
Select Case UCase(helpcmd)
    Case "NICK"
        do_cmd_help cptr.index, cptr.Nick, "NICK", hlp.NickSyntax, hlp.Nick, hlp.NickExample
    Case "OPER"
        If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
          SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
          Exit Function
        End If
        do_cmd_help cptr.index, cptr.Nick, "OPER", hlp.OperSyntax, hlp.Oper, hlp.OperExample
    Case "GNOTICE"
        If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
          SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
          Exit Function
        End If
        do_cmd_help cptr.index, cptr.Nick, "GNOTICE", hlp.GNoticeSyntax, hlp.GNotice, hlp.GNoticeExample
    Case "WHO"
        do_cmd_help cptr.index, cptr.Nick, "WHO", hlp.WhoSyntax, hlp.Who, hlp.WhoExample
    Case "CMD"
        SendWsock cptr.index, RPL_HELPHDR & " " & cptr.Nick, ":~~~~~ignitionServer Help~~~~~"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":NICK - Change your nickname"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":WHO - Find a User on the server"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":For more info on these commands please use /ircxhelp <command>"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPTLR & " " & cptr.Nick, ":End of /IRCXHELP"
    Case "OPERCMD"
        If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
          SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
          Exit Function
        End If
        SendWsock cptr.index, RPL_HELPHDR & " " & cptr.Nick, ":~~~~~ignitionServer Help~~~~~"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":OPER - Identify yourself as an IRC Operator"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":GNOTICE - Send a Global Notice to all who can see server messages"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":For more info on these commands please use /ircxhelp <command>"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPTLR & " " & cptr.Nick, ":End of /IRCXHELP"
    Case Else
        SendWsock cptr.index, RPL_HELPHDR & " " & cptr.Nick, ":~~~~~ignitionServer Help~~~~~"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":For General Commands: /ircxhelp cmd"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":For Operator Commands: /ircxhelp opercmd"
        SendWsock cptr.index, RPL_HELPHLP & " " & cptr.Nick, ":"
        SendWsock cptr.index, RPL_HELPTLR & " " & cptr.Nick, ":End of /IRCXHELP"

    End Select
End Function

Public Function do_cmd_help(index As Long, Nick As String, cmdName As String, cmdSyntax As String, cmdHelp As String, cmdExample As String) As Long
    SendWsock index, RPL_HELPHDR & " " & Nick, ":~~~~~ignitionServer Help - " & cmdName & "~~~~~"
    SendWsock index, RPL_HELPHLP & " " & Nick, ":"
    SendWsock index, RPL_HELPHLP & " " & Nick, ":SYNTAX: " & cmdSyntax
    SendWsock index, RPL_HELPHLP & " " & Nick, ":EXAMPLE: " & cmdExample
    SendWsock index, RPL_HELPHLP & " " & Nick, ":" & cmdHelp
    SendWsock index, RPL_HELPHLP & " " & Nick, ":"
    SendWsock index, RPL_HELPTLR & " " & Nick, ":End of /IRCXHELP"
End Function

Public Function SetHelp()
'**** Localization
'**** Edit the text here to change the messages
'TODO: Load from a file that can be edited in notepad
hlp.Nick = "Used to change your current nickname to a new one."
hlp.NickSyntax = "/nick <NewNick>"
hlp.NickExample = "/nick Ziggy"
hlp.Oper = "Used to login as an IRC Operator. You must have a username and password assigned by the Server Administrator."
hlp.OperSyntax = "/oper <UserName> <PassWord>"
hlp.OperExample = "/oper Ziggy HamstersRule"
hlp.Who = "Used to find users on the network. Will not work if the user is hidden (has +i set on themselves)."
hlp.WhoSyntax = "/who <HostMask>"
hlp.WhoExample = "/who Ziggy"
hlp.GNotice = "Sends a notice to all IRC Operators and those who can see server messages (+s) on every server. Depending on your client, you may have to add a : before you type your text. (/gnotice :<Text>)"
hlp.GNoticeSyntax = "/gnotice <Text>"
hlp.GNoticeExample = "/gnotice I crashed services -- please wait while I restart them"
End Function

