class NoFoundCdn {
    constructor(root) {
        this.root = root
    }

    render() {
        this.root.innerHTML = `
            <div class="d-flex justify-content-center p-5">
                <h4 class="text-muted">DESAFORTUNADAMENTE NO ENCONTRAMOS NINGUNA CDN</h4>
            </div>
        `
    }
}

export default NoFoundCdn
