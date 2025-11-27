require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password") }

  describe "send_verification_code" do
    before do
      user.update!(verification_code: "123456")
    end

    let(:mail) { UserMailer.send_verification_code(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your Verification Code")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["from@example.com"]) # Adjust if you have a specific default from
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("123456")
    end
  end

  describe "send_password_reset" do
    before do
      user.update!(reset_token: "reset_token_123")
    end

    let(:mail) { UserMailer.send_password_reset(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Password Reset Instructions")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("reset_token_123")
    end
  end
end
