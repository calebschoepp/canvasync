class ApplicationMailer < ActionMailer::Base
  # Mandated by FR-3: Change.Password

  default from: 'from@example.com'
  layout 'mailer'
end
