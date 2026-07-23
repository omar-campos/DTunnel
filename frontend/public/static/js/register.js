class RegisterService {
    async register(data) {

        const response = await fetch('/register', {
            method: 'POST',
            body: JSON.stringify({
                username: data.username,
                password: data.password,
                email: data.email,
            }),
            headers: {
                'csrf-token': data.csrfToken,
                'Content-Type': 'application/json'
            }
        })

        if (response.status === 201) {
            return;
        }

        const csrfTokenRefresh = getCsrfTokenRefresh(response);
        if (csrfTokenRefresh) {
            data.registerForm.updateCsrfToken(csrfTokenRefresh)
        }

        const result = await response.json();
        if (result.message) throw new Error(result.message);

    }
}

class RegisterForm {
    constructor() {
        this.element = document.querySelector('form');
        this.csrfToken = getCsrfTokenHead();
    }

    get formData() {
        return new FormData(this.element)
    }

    async getData() {
        await this.#validate();
        return {
            username: this.formData.get('username'),
            password: this.formData.get('password'),
            email: this.formData.get('email'),
            csrfToken: this.csrfToken
        }
    }

    updateCsrfToken = (token) => this.csrfToken = token;

    deleteFormData = () => this.element.reset()

    async #validate() {

        if (this.formData.get('password') != this.formData.get('confirm_password')) {
            throw new Error('Las contraseñas no coinciden.')
        }

        const pattern = /^[a-zA-Z0-9@]+$/;
        const username = this.formData.get('username');

        if (!pattern.test(username)) {
            throw new Error('Este nombre de usuario no es válido.')
        }

        if (username.length < 6) {
            throw new Error('Usa un nombre de usuario más largo.')
        }

        if (this.formData.get('password').length < 6) {
            throw new Error('Usa una contraseña más larga.')
        }

    }

    setOnSubmitListener(fn) {
        this.element.addEventListener('submit', e => {
            e.preventDefault();
            e.stopPropagation();
            fn();
        })
    }
}

class RegisterModalSuccess {
    constructor() {
        this.element = document.createElement('div');
        this.element.className = 'modal fade'
        this.element.innerHTML = `
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content bg-dark text-white">
                    <div class="modal-header">
                        <h5 class="modal-title">¡Felicidades!</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"
                            aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="text-center">
                            <img src="https://cdn-icons-png.flaticon.com/512/1642/1642423.png" width="200" height="200">
                            <p class="fs-2 text-success">Cuenta registrada.</p>
                        </div>
                        <div class="form-control bg-dark text-white __data" style="overflow-y: auto;">
                            <b>
                                <p class="mb-2">Correo: <span class="__email"></span></p>
                            </b>
                            <b>
                                <p class="mb-2">Contraseña: <span class="__password"></span></p>
                            </b>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <div class="d-flex w-100 gap-3">
                            <div class="flex-fill">
                            <a href="${window.location.origin + '/user'}" class="flex-fill text-decoration-none">
                            <button type="button" class="btn btn-dark w-100 border">Cerrar</button>
                            </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `

        this.modal = new bootstrap.Modal(this.element);
    }

    setData(data) {
        this.element.querySelector('.__email').innerHTML = data.email;
        this.element.querySelector('.__password').innerHTML = data.password;
    }

    show() {
        this.modal.show();
    }

    hide() {
        this.modal.hide();
    }
}

class RegisterModalError {
    constructor() {
        this.element = document.createElement('div');
        this.element.className = 'modal fade'
        this.element.innerHTML = `
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content bg-dark text-white">
                    <div class="modal-header">
                        <h5 class="modal-title">ERROR</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"
                            aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <span class="__error_message">
                            <p class="fs-3 text-danger">
                                No fue posible crear su acceso, póngase en contacto con soporte.
                            </p>
                        </span>
                    </div>
                </div>
            </div>
        `

        this.modal = new bootstrap.Modal(this.element);
    }

    setMessage(data) {
        this.element.querySelector('.__error_message').innerHTML = `<p class="fs-3 text-danger">${data}</p>`;
    }

    show() {
        this.modal.show();
    }

    hide() {
        this.modal.hide();
    }
}

const startBtnLoader = () => {
    const loader = document.querySelector('.__btn_loader');
    const text = document.querySelector('.__btn_text');

    text.parentElement.setAttribute('disabled', '')

    if (loader.classList.contains('d-none')) {
        loader.classList.remove('d-none')
    }

    if (!text.classList.contains('d-none')) {
        text.classList.add('d-none')
    }
}

const stopBtnLoader = () => {
    const loader = document.querySelector('.__btn_loader');
    const text = document.querySelector('.__btn_text');

    text.parentElement.removeAttribute('disabled')

    if (!loader.classList.contains('d-none')) {
        loader.classList.add('d-none')
    }

    if (text.classList.contains('d-none')) {
        text.classList.remove('d-none')
    }
}

const main = async () => {
    const modalSuccess = new RegisterModalSuccess();
    const modalError = new RegisterModalError();

    const registerForm = new RegisterForm();
    const registerService = new RegisterService();

    const registerSuccessfully = async (formData, register) => {
        try {
            modalSuccess.setData(formData);
            modalSuccess.show()
            registerForm.deleteFormData();
        } catch (e) {
            modalError.show();
        }
    }

    const startProcessRegister = async () => {
        startBtnLoader();
        try {
            const data = await registerForm.getData();
            const register = await registerService.register({ ...data, registerForm });
            await registerSuccessfully(data, register);
        } catch (error) {
            showToastError(error)
        } finally {
            stopBtnLoader();
        }
    };

    registerForm.setOnSubmitListener(() => startProcessRegister());
}

main();
