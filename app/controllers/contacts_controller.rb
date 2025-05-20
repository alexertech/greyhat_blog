# frozen_string_literal: true

class ContactsController < ApplicationController
  before_action :authenticate_user!, except: %i[new create]
  before_action :set_contact, only: %i[show destroy]

  # GET /contacts
  # GET /contacts.json
  def index
    @contacts = Contact.all
  end

  # GET /contacts/1
  # GET /contacts/1.json
  def show; end

  # GET /contacts/new
  def new
    @contact = Contact.new
    # Store the current time in the session for time-based bot detection
    session[:form_displayed_at] = Time.current
    
    # Reset the submission counter for this session
    session[:contact_submissions_count] ||= 0
    
    # Check if showing success message
    @success = flash[:success].present?
  end

  # POST /contacts
  # POST /contacts.json
  def create
    @contact = Contact.new(contact_params)
    
    # Set the time the form was displayed for time-based bot detection
    @contact.form_displayed_at = session[:form_displayed_at]
    
    # Rate limiting - track submissions
    session[:contact_submissions_count] ||= 0
    session[:contact_submissions_count] += 1
    
    # If too many submissions in a short time, reject
    if session[:contact_submissions_count] > 3
      @contact.errors.add(:base, "Demasiados intentos. Por favor intente más tarde.")
      return render :new
    end
    
    if @contact.save
      session[:contact_submissions_count] = 0
      flash[:success] = true
      flash[:notice] = 'Mensaje guardado! Recibirá nuestra respuesta en breve.'
      redirect_to new_contact_path
    else
      render :new
    end
  end

  # DELETE /contacts/1.json
  def destroy
    @contact.destroy
    respond_to do |format|
      format.html do
        redirect_to contacts_url, notice: 'Contact was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  def clean
    Contact.destroy_all
    respond_to do |format|
      format.html do
        redirect_to contacts_url, notice: 'Contact messages deleted.'
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contact
    @contact = Contact.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contact_params
    params.require(:contact).permit(:name, :email, :message, :website)
  end
end
