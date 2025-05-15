# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactsController, type: :controller do
  let(:valid_attributes) {
    {
      name: 'Test User',
      email: 'test@example.com',
      message: 'This is a test contact message'
    }
  }

  let(:invalid_attributes) {
    {
      name: '',
      email: 'not-an-email',
      message: ''
    }
  }

  let(:spam_attributes) {
    {
      name: 'Spam Bot',
      email: 'spam@example.com',
      message: 'Spam message',
      website: 'https://spam-site.com'
    }
  }

  let(:user) { User.create(email: 'admin@example.com', password: 'password123456') }

  describe 'GET #index' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns all contacts as @contacts' do
        contact = Contact.create(valid_attributes)
        get :index
        expect(assigns(:contacts)).to eq([contact])
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #show' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        contact = Contact.create(valid_attributes)
        get :show, params: { id: contact.to_param }
        expect(response).to be_successful
      end

      it 'assigns the requested contact as @contact' do
        contact = Contact.create(valid_attributes)
        get :show, params: { id: contact.to_param }
        expect(assigns(:contact)).to eq(contact)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        contact = Contact.create(valid_attributes)
        get :show, params: { id: contact.to_param }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new contact as @contact' do
      get :new
      expect(assigns(:contact)).to be_a_new(Contact)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Contact' do
        expect {
          post :create, params: { contact: valid_attributes }
        }.to change(Contact, :count).by(1)
      end

      it 'assigns a newly created but unsaved contact as @contact for the success message' do
        post :create, params: { contact: valid_attributes }
        expect(assigns(:contact)).to be_a_new(Contact)
      end

      it 'renders the new template with a success notice' do
        post :create, params: { contact: valid_attributes }
        expect(response).to render_template(:new)
      end
    end

    context 'with invalid params' do
      it 'does not create a new Contact' do
        expect {
          post :create, params: { contact: invalid_attributes }
        }.to change(Contact, :count).by(0)
      end

      it 'assigns a newly created but unsaved contact as @contact' do
        post :create, params: { contact: invalid_attributes }
        expect(assigns(:contact)).to be_a_new(Contact)
      end

      it 're-renders the "new" template' do
        post :create, params: { contact: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end

    context 'with spam params (honeypot filled)' do
      it 'does not create a new Contact' do
        expect {
          post :create, params: { contact: spam_attributes }
        }.to change(Contact, :count).by(0)
      end

      it 're-renders the "new" template' do
        post :create, params: { contact: spam_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'destroys the requested contact' do
        contact = Contact.create(valid_attributes)
        expect {
          delete :destroy, params: { id: contact.to_param }
        }.to change(Contact, :count).by(-1)
      end

      it 'redirects to the contacts list' do
        contact = Contact.create(valid_attributes)
        delete :destroy, params: { id: contact.to_param }
        expect(response).to redirect_to(contacts_url)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        contact = Contact.create(valid_attributes)
        delete :destroy, params: { id: contact.to_param }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE #clean' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'destroys all contacts' do
        Contact.create(valid_attributes)
        Contact.create(valid_attributes.merge(name: 'Another User'))
        
        expect {
          delete :clean
        }.to change(Contact, :count).to(0)
      end

      it 'redirects to the contacts list' do
        delete :clean
        expect(response).to redirect_to(contacts_url)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        delete :clean
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end 