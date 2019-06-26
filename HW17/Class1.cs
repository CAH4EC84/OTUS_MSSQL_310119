using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;


public class MailSender{
    public static int Send(string subject, string mailTo, string attach)
    {
        try { 
            string mailFrom = "robot@medline.spb.ru";
            string attachPath = @"D:\MedlineAdminSoft\Temp\BIRJA.INI";
            System.Net.Mail.SmtpClient client = new SmtpClient("mx.russia.spb.ru", 25);
            client.UseDefaultCredentials = false;
            client.DeliveryMethod = SmtpDeliveryMethod.Network;
            client.Credentials = new System.Net.NetworkCredential("robot@russia.spb.ru", "somepasswd");
            MailMessage mailMessage = new MailMessage(mailFrom, mailTo);
            mailMessage.Subject = subject;
            mailMessage.Body = "Отчет сгенерирован";
            client.Send(mailMessage);
            return 1;
        }
        catch (Exception ex) {
            return 0;
        }
    }

}
