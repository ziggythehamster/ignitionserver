Attribute VB_Name = "m_extracommands"
'ignitionServer is (C) Keith Gable and Contributors
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'Contributors:        Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'                     Reid Burke  (Airwalk) <airwalk@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: m_extracommands.bas,v 1.7 2004/06/30 21:39:29 ziggythehamster Exp $
'
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

Option Explicit
#Const Debugging = 0

Public Function m_chanpass(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = targetchannel
'parv[1] = password
'-DG

#If Debugging = 1 Then
  SendSvrMsg "CHANPASS called! (" & cptr.Nick & ")"
#End If

Dim Chan As clsChannel
'gp = Given Pass

'check if null (not enough params)
If Len(parv(0)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHANPASS")
  Exit Function
End If
If Len(parv(1)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHANPASS")
  Exit Function
End If
Set Chan = Channels(parv(0))
If parv(1) = Chan.Prop_Ownerkey And Len(Chan.Prop_Ownerkey) > 0 Then
    Chan.Member.Item(cptr.Nick).IsOwner = True
    SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick, 0
    SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
End If
If parv(1) = Chan.Prop_Hostkey And Len(Chan.Prop_Hostkey) > 0 And Chan.Member.Item(cptr.Nick).IsOwner = False Then
    Chan.Member.Item(cptr.Nick).IsOp = True
    SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
    SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
End If


End Function

Public Function m_passcrypt(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = CryptType
'parv[1] = PassToBeCrypted
Dim Pass As String
If UCase$(parv(0)) = "MD5" Then
    Pass = oMD5.MD5(parv(1))
    SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Encrypted " & parv(1) & " to MD5 as " & Pass, SPrefix
Else
    SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Valid Options: MD5", SPrefix
End If
End Function

Public Function m_chgnick(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = Nick
'parv[1] = New nick
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
If Not (cptr.CanChange Or cptr.IsNetAdmin) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
If UBound(parv) <> 1 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGNICK")
  Exit Function
End If
If Len(parv(1)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGNICK")
  Exit Function
End If
If Not GlobUsers(parv(1)) Is Nothing Then  'in case the nickname specified is already in use -Dill
  SendWsock cptr.index, "NOTICE", ":*** Nickname " & parv(1) & " is in use! Cannot change nickname.", SPrefix
  Exit Function
End If
Dim User As clsClient
Set User = GlobUsers(parv(0))
If User Is Nothing Then
  SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
  Exit Function
End If
If do_nick_name(parv(1)) = 0 Then
  SendWsock cptr.index, "NOTICE", ":*** The nickname " & parv(1) & " contains illegal characters.", SPrefix
  Exit Function
End If

Dim tmpNick As String
Dim tmpPrefix As String
Dim ByteArr() As Byte, Members() As clsChanMember
tmpNick = User.Nick
tmpPrefix = User.Prefix
User.Nick = parv(1)
SendSvrMsg "*** " & cptr.Nick & " changed the nickname of " & tmpNick & " to " & parv(1)
'now to do the standard nick change -z
Dim AllVisible As New Collection
Dim NickX As Integer
Dim I As Integer
ReDim RecvArr(1)
'notify channels -z
For NickX = 1 To User.OnChannels.Count
  Members = User.OnChannels.Item(NickX).Member.Values
  For I = LBound(Members) To UBound(Members)
    If Members(I).Member.Hops = 0 Then
      If Not Members(I).Member Is User Then
        On Local Error Resume Next
        AllVisible.Add Members(I).Member.index, CStr(Members(I).Member.index)
      End If
    End If
  Next I
Next NickX
For I = 1 To AllVisible.Count
  'send notificaiton -z
  Call SendWsock(AllVisible(I), "NICK", parv(1), tmpPrefix)
Next I
SendToServer "NICK :" & parv(1), tmpNick
SendWsock User.index, "NICK", parv(1), tmpPrefix

Dim tempVar As String
'assign the new nick to the database -Dill
If Len(User.Nick) > 0 Then GlobUsers.Remove tmpNick
GlobUsers.Add parv(1), User
tempVar = tmpNick
User.Nick = parv(1)
GenerateEvent "USER", "NICKCHANGE", Replace(tmpPrefix, ":", ""), Replace(tmpPrefix, ":", "") & " " & cptr.Nick
User.Prefix = ":" & User.Nick & "!" & User.User & "@" & User.Host
Dim WasOwner As Boolean, WasOp As Boolean, WasHOp As Boolean, WasVoice As Boolean
Dim tmpData As Integer
For NickX = 1 To User.OnChannels.Count
     With User.OnChannels.Item(NickX).Member
       WasOwner = .Item(tempVar).IsOwner
       WasOp = .Item(tempVar).IsOp
       WasHOp = .Item(tempVar).IsHOp
       WasVoice = .Item(tempVar).IsVoice
       tmpData = 0
       If WasOwner Then tmpData = 6
       If WasOp Then tmpData = 4 'WTF is this bit for? Any Ideas Ziggy? - DG
                              'looks like a temp variable for the user level - Ziggy
       If WasVoice Then tmpData = tmpData + 1
       .Remove tempVar
       .Add CLng(tmpData), User
     End With
Next NickX
End Function


Public Function m_chghost(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = Nick
'parv[1] = New Host
Dim User As clsClient
If cptr.AccessLevel = 4 Then
  Set User = GlobUsers(parv(0))
  If User Is Nothing Then Exit Function
  User.Host = parv(1)
  ':Nick CHGHOST OtherNick NewHost
  SendToServer_ButOne "CHGHOST " & User.Nick & " " & parv(1), cptr.ServerName, sptr.Nick
  If User.Hops = 0 Then
    'don't send the bloody notice if sptr is NickServ
    If StrComp(UCase(sptr.Nick), "NICKSERV") <> 0 Then SendSvrMsg "*** " & sptr.Nick & " changed the hostname of " & User.Nick & " to " & parv(1)
    SendWsock User.index, "NOTICE " & User.Nick, ":" & sptr.Nick & " changed your hostname to " & parv(1), SPrefix
  End If
Else
  If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
      Exit Function
  End If
  If Not (cptr.CanChange Or cptr.IsNetAdmin) Then
      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
      Exit Function
  End If
  If UBound(parv) <> 1 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGHOST")
    Exit Function
  End If
  If Len(parv(1)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGHOST")
    Exit Function
  End If
  Set User = GlobUsers(parv(0))
  If User Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
    Exit Function
  End If
  User.Host = parv(1)
  SendToServer "CHGHOST " & User.Nick & " " & parv(1), cptr.Nick
  If User.Hops = 0 Then
    SendSvrMsg "*** " & cptr.Nick & " changed the hostname of " & User.Nick & " to " & parv(1)
    SendWsock User.index, "NOTICE " & cptr.Nick, ":" & cptr.Nick & " changed your hostname to " & parv(1), SPrefix
  End If
End If
End Function

Public Function m_mdie(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
SendSvrMsg "*** Notice -- MDIE called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MDIE")
    Exit Function
End If
If cptr.IP <> "127.0.0.1" Then
  SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
  Exit Function
End If
Dim ID As Long
Dim F As Long
F = FreeFile
If Dir(App.Path & "\monitor.id") = vbNullString Then
  SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
  Exit Function
End If
Open App.Path & "\monitor.id" For Input As #F
Input #F, ID
Close #F

If parv(0) = ID Then
    Dim I As Long   'close all connection properly -Dill
    For I = 1 To UBound(Users)
        If Not Users(I) Is Nothing Then
            SendWsock I, "NOTICE " & Users(I).Nick, SPrefix & " is quitting."
            Sockets.CloseIt I
            m_error Users(I), "Closing Link: (" & ServerName & " is quitting)"
        End If
    Next I
    Kill App.Path & "\monitor.id" '// prevent exploitation if it ever occurs -zg
    Terminate
Else
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
End Function
