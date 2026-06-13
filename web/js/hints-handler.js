export default class HintsHandler {
    /*
        * @param {jQuery} $container - The jQuery element where hints will be appended.
    */
    constructor($container) {
        this.$container = $container;
        this.$hint = null;
        this.timeout = null;
    }

    /**
     * Creates and displays a hint.
     * @param {string} description - The main text of the hint.
     * @param {string} control - Optional control text to display.
     * @param {Object} configs - Optional configurations for the hint.
     * @param {boolean} configs.infoIcon - Whether to show an info icon.
     * @param {number} configs.time - Duration in milliseconds before the hint auto-removes.
     */
    create(description, control, configs = {}) {
        this.$hint = $(`
        <div class="hints__container animate__animated animate__fadeInRight">
            ${configs.infoIcon ? `<span class="hint-info-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg></span>` : ""}
            ${control ? `<p class="hint-control">${control}</p>` : ""}
            <p class="hint-description">${description}</p>
        </div>
        `);

        if (configs.time && configs.time > 0) {
            this.timeout = setTimeout(() => {
                this.remove();
            }, configs.time);
        }

        this.$container.append(this.$hint);
    }

    /**
     * Removes the hint with a fade-out animation.
    */
    remove() {
        this.$hint.addClass("animate__fadeOutRight");
        this.$hint.on("animationend", () => {
            this.$hint.remove();
        });
        if (this.timeout) {
            clearTimeout(this.timeout);
            this.timeout = null;
        }
    }
}