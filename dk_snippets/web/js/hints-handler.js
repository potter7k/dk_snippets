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
            ${configs.infoIcon ? `<span class="material-symbols-outlined">info</span>` : ""}
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