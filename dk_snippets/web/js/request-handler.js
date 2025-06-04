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

    constructor(id, title, timer, description, acceptText, denyText) {
        this.#id = id;
        this.#title = title;
        this.#timer = timer;
        this.#description = description;
        this.#acceptText = acceptText ?? "Aceitar (Y)";
        this.#denyText = denyText ?? "Recusar (U)";
    }

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

    close() {
        this.#mainDiv.removeClass("animate_fade_in_grow");
        this.#mainDiv.addClass("animate_fade_out_grow");

        $(".animate_fade_out_grow").on("animationend", function() {
            $(this).hide();
            $(this).remove();
        });
    }

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

    decreaseTimer() {
        if (this.#timer > 0) {
            this.#timer = this.#timer - 1;
            this.#timerDiv.text(this.#timer);
        }
    }

    hasFinished() {
        return this.#timer <= 0;
    }

    getTimer() {
        return this.#timer;
    }

    getId() {
        return this.#id;
    }
}