/*
 * Web log: copies everything written to stdout (printf, ESP_LOGx) into a RAM
 * ring buffer, while still sending it to the serial console. The web page
 * /logs reads it through /logs_data?from=<offset>.
 *
 * Secrets never go to the RAM log (it can be read on /logs and downloaded as
 * a .log file that is easy to share):
 *   - weblog_secret() prints passwords/keys on the serial console only;
 *   - the serial console session (REPL task: what is typed, like
 *     "web_auth --pass ...", and the command replies) stays on the serial
 *     port only. Messages of the other tasks are kept as before.
 */
#ifndef _WEBLOG_H
#define _WEBLOG_H

#include <stdint.h>
#include <stddef.h>

#define WEBLOG_SIZE   16384     /* bytes kept in RAM */

/* name of the esp_console REPL task (components/console/esp_console_repl_*.c) */
#define WEBLOG_CONSOLE_TASK  "console_repl"

void weblog_init(void);         /* call as early as possible in app_main() */

/* copies up to max bytes starting at absolute offset 'from'.
 * *start = oldest offset still available, *next = offset for the next call */
size_t weblog_read(uint32_t from, char *dst, size_t max, uint32_t *start, uint32_t *next);

/* printf() that writes the formatted text on the serial console only.
 * web_text (may be NULL) is stored in the RAM log in its place, e.g.
 *   weblog_secret("Soft AP password: (hidden on the web log)\n",
 *                 "Soft AP password: %s\n", pass); */
void weblog_secret(const char *web_text, const char *fmt, ...) __attribute__((format(printf, 2, 3)));

/* copy of uri for logs, without the password of "scheme://user:pass@host"
 * (-> "scheme://user:***@host"). Returns out. */
const char *weblog_uri(const char *uri, char *out, size_t size);

#endif
