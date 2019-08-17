DEFINE defaultSchema = '&1'
DEFINE mailServer    = 'mail.spatialdbadvisor.com'

create or replace
package email
AUTHID CURRENT_USER
as
  type array         is table of varchar2(255);
  TYPE "STRINGARRAY" is table of varchar2(2048) ;
  c_mailhost         varchar2(255) := '&&mailServer..';
  c_from_email       varchar2(255) := 'admin@&&mailServer..';
  c_to_email         varchar2(255) := 'me@google.com';
  c_cc_email         varchar2(100) := 'simon@spatialdbadvisor.com';

  procedure send( p_from    in varchar2    default c_from_email,
                  p_to      in stringarray default stringarray(c_to_email),
                  p_cc      in stringarray default stringarray(),
                  p_bcc     in stringarray default stringarray(),
                  p_subject in varchar2    default NULL,
                  p_body    in long        default NULL );
                  
end;
/
show errors

create or replace
package body email
as

  -- Now we have the implementation of our published function the one people will
  -- actually call to send mail.  It starts with an internal procedure writeData that
  -- is used to simplify the sending of the email headers (the To:, From:, Subject:
  -- records).  If the header record is NOT NULL, this routine will use the
  -- appropriate UTL_SMTP call to send it along with the necessary end of line
  -- marker (the carriage return/line feed):

  procedure send( p_from    in varchar2    default c_from_email,
                  p_to      in stringarray default stringarray(c_to_email),
                  p_cc      in stringarray default stringarray(),
                  p_bcc     in stringarray default stringarray(),
                  p_subject in varchar2    default NULL,
                  p_body    in long        default NULL )
  is
    l_date      varchar2(255);
    v_ignore    varchar2(4000);
    v_mail_conn utl_smtp.connection;

    PROCEDURE send_header(p_name IN VARCHAR2, p_header IN VARCHAR2) 
    AS
    BEGIN
        if ( p_name is not null AND p_header is not null )
        then
            UTL_SMTP.WRITE_DATA(v_mail_conn, p_name || ': ' || p_header || UTL_TCP.CRLF);
        end if;
    END;

    -- Next we have an internal (unpublished) function to send an email to many
    -- recipients it in effect addresses the email.  At the same time, it builds the
    -- To: or Cc: lines that we?ll eventually send as part of the email itself and
    -- returns that formatted string.  It was implemented as a separate function since
    -- we need to do this separately for the To, CC, and BCC lists:
    --
    function address_email(p_string     in varchar2,
                           p_recipients in stringarray,
                           p_rcpt       in boolean default true)
    return varchar2
    is
      l_recipients long;
    begin
      if ( p_recipients is null ) then
         return null;
      end if;
      for i in 1 .. p_recipients.count
      loop
         if (p_rcpt) Then
            utl_smtp.rcpt(v_mail_conn, p_recipients(i) );
         end if;
         if ( l_recipients is null ) then
             l_recipients := p_string || p_recipients(i) ;
         else
             l_recipients := l_recipients || ', ' || p_recipients(i);
         end if;
      end loop;
      return l_recipients;
    end address_email;
  
  -- Now we are ready to actually send the mail.  This part is not very different from
  -- the very simple routine we started with.  It begins in exactly the same fashion
  -- by connecting to the SMTP server and starting a session:

  begin
    begin
        select to_char(SYSTIMESTAMP, value,'NLS_DATE_LANGUAGE=' || (select value from nls_database_parameters where parameter='NLS_DATE_LANGUAGE') ) as send_date
          into l_date
          from nls_database_parameters 
         where parameter = 'NLS_TIMESTAMP_TZ_FORMAT';
        exception
           when others then
             l_date := to_char(SYSTIMESTAMP, 'Dy, dd Mon yyyy hh24:mi:ss tzhtzm','NLS_DATE_LANGUAGE=American');
    end;

    v_mail_conn := utl_smtp.open_connection(c_mailhost, 25);
    utl_smtp.helo(v_mail_conn, c_mailhost);
    utl_smtp.mail(v_mail_conn, nvl( p_from, c_from_email ));
    if ( p_to is null or p_to.count > 0 ) then
       utl_smtp.rcpt(v_mail_conn, c_to_email);    
    else 
       v_ignore := address_email('To: ',p_to);
    End if;

    -- Now, we use the OPEN_DATA call to start sending the body of the email.
    utl_smtp.open_data(v_mail_conn);
    
    --  Generate the header section of data.
    send_header('From', NVL(p_from,c_from_email) );
    if ( p_to is null OR p_to.count = 0 ) then
       send_header('To', c_to_email );    
    else 
       
       send_header('To', address_email('To: ',p_to,false) );
    End if;
    if ( p_cc is not null and p_cc.count > 0 ) then
       send_header(  'Cc', address_email('Cc: ',p_cc,false) );
    End If;
    if ( p_bcc is not null and p_bcc.count > 0 ) then
       send_header( 'Bcc', address_email('Bcc: ',p_bcc,false) );
    end if;
    send_header(    'Date ', l_date );
    send_header( 'Subject ', nvl( p_subject, '(no subject)' ) );
    utl_smtp.write_data( v_mail_conn, '' || UTL_TCP.CRLF );
    -- send the body of the email (the contents of the email)
    utl_smtp.write_data(v_mail_conn, p_body );
    -- Terminate the email.
    utl_smtp.close_data(v_mail_conn );
    utl_smtp.quit(v_mail_conn);
  end send;
  
end EMAIL;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'EMAIL';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on email to public;


QUIT;

-- Example 
 BEGIN
 send(p_from    => c_from_email,
      p_to      => stringarray( c_to_email ),
      p_cc      => stringarray( c_cc_email ),
      p_bcc     => stringarray( ),
      p_subject => 'MapInfo Export and Materialised View Refresh',
      p_body    => 'Test' );
 END;
 /
 

/*
begin
  apex_mail.send(
    p_to => 'sgreener@netspace.net.au',
    p_from => 'simon@spatialdbadvisor.com',
    p_body => 'Hello wicked Hobittsssessss, '|| CHR(13) || CHR(10) || 'My precioussss Oracle UTL_SMTP and MAIL package works!'|| CHR(13) || CHR(10) || ' Gollum.'
  );
  apex_mail.push_queue;
end;
/

begin
   &defaultSchema..email.send
    ( p_sender_email => 'simon@spatialdbadvisor.com',
      p_from => 'simon@spatialdbadvisor.com',
      p_to => &defaultSchema..email.stringarray( 'sgreener@netspace.net.au' ),
      p_cc => &defaultSchema..email.stringarray( ),
      p_bcc => &defaultSchema..email.stringarray( ),
      p_subject => 'Test Email',
      p_body => 'Hello wicked Hobittsssessss, '|| CHR(13) || CHR(10) || 'My precioussss Oracle UTL_SMTP and MAIL package works!'|| CHR(13) || CHR(10) || ' Gollum.' );
end;
/
show errors
*/

