import { sendClient } from "./script.js";

const $requests = $("#requests");

export default class RequestHandler {
    #id;
    #title;
    #timer;
    #description;

    #acceptText;
    #denyText;

    #timerDiv;
    #mainDiv;
    #acceptButton;
    #denyButton;
    #requestInterval;

    /**
    * @param {string} id - The unique identifier for the request.
    * @param {string} title - The title of the request.
    * @param {number} timer - The duration of the request in seconds.
    * @param {string} description - The description of the request.
    * @param {string} acceptText - The text for the accept button.
    * @param {string} denyText - The text for the deny button.
    */
    constructor(id, title, timer, description, acceptText, denyText) {
        this.#id = id;
        this.#title = title;
        this.#timer = timer;
        this.#description = description;
        this.#acceptText = acceptText ?? "Aceitar (Y)";
        this.#denyText = denyText ?? "Recusar (U)";
    }

    /**
     * Displays the request UI.
     */
    show() {
        const $main = this.#createDiv();
        $requests.append($main);

        this.#requestInterval = setInterval(() => {
            this.decreaseTimer();

            if (this.hasFinished()) {
                this.close();
                clearInterval(this.#requestInterval);
                sendClient("requestResponse", {
                    id: this.#id,
                    success: false
                });
            }
        }, 1000);
    }

    /**
     * Closes the request UI.
     */
    close() {
        this.#mainDiv.removeClass("animate_fade_in_grow");
        this.#mainDiv.addClass("animate_fade_out_grow");

        $(".animate_fade_out_grow").on("animationend", function() {
            $(this).hide();
            $(this).remove();
        });
    }

    /**
     * Handles the accept action.
     */
    onAccept() {
        if (this.#acceptButton) {
            this.#acceptButton.addClass('hover-effect');
        }

        clearInterval(this.#requestInterval);
        sendClient("requestResponse", {
            id: this.#id,
            success: true
        });
        this.close();
    }

    /**
     * Handles the deny action.
     */
    onDeny() {
        if (this.#denyButton) {
            this.#denyButton.addClass('hover-effect');
        }

        clearInterval(this.#requestInterval);
        sendClient("requestResponse", {
            id: this.#id,
            success: false
        });
        this.close();
    }

    /**
     * Creates the main request div.
     * @returns {jQuery} The jQuery element representing the request UI.
     */
    #createDiv() {
        this.#mainDiv = $('<main>').addClass('requests__container animate_fade_in_grow');

        const header = $('<header>').addClass('requests__container__header');
        const h1 = $('<h1>').text(this.#title);
        const h2 = $('<h2>').text(this.#timer);
        this.#timerDiv = h2;

        header.append(h1, h2);

        const descriptionDiv = $('<div>').addClass('requests__container__description');
        const p = $('<p>').html(this.#description);
        descriptionDiv.append(p);

        const buttonsDiv = $('<div>').addClass('requests__container__buttons');
        this.#denyButton = $('<button>')
            .attr('type', 'button')
            .attr('id', 'request-deny')
            .text(this.#denyText);
        
        this.#denyButton.click((event) => {
            event.preventDefault();
            this.onDeny();
        });

        this.#acceptButton = $('<button>')
            .attr('type', 'button')
            .attr('id', 'request-accept')
            .text(this.#acceptText);

        this.#acceptButton.click((event) => {
            event.preventDefault();
            this.onAccept();
        });

        buttonsDiv.append(this.#denyButton, this.#acceptButton);

        this.#mainDiv.append(header, descriptionDiv, buttonsDiv);

        return this.#mainDiv;
    }

    /**
     * Decreases the timer by 1 second.
     */
    decreaseTimer() {
        if (this.#timer > 0) {
            this.#timer = this.#timer - 1;
            this.#timerDiv.text(this.#timer);
        }
    }

    /**
     * Checks if the request has finished.
     * @returns {boolean} True if the request has finished, false otherwise.
     */
    hasFinished() {
        return this.#timer <= 0;
    }

    /**
     * Gets the current timer value.
     * @returns {number} The current timer value in seconds.
     */
    getTimer() {
        return this.#timer;
    }

    /**
     * Gets the request ID.
     * @returns {string} The request ID.
     */
    getId() {
        return this.#id;
    }
}