/**
 * @description Promise implementation in apex, per:
 * https://developer.salesforce.com/blogs/2020/01/learn-moar-in-spring-20-implementing-promises-with-transaction-finalizers.html
 * Tested By: PromiseTest
 */
public class Chain implements Finalizer {
    private Promise[] promises;
    private Object passThrough;
    private Boolean continueAfterFailure;
    @TestVisible private static Promise nextPromise;
    // Since there's a max stack depth for queueable chains in tests, we'll not call the queueable chain by default for tests, but
    // allow tests to override that behavior.
    @TestVisible private static Boolean callQueueableChain = !Test.isRunningTest();

    /**
     * @description Constructor, intended for Promise to call
     * @param promises The chain of promises
     * @param passThrough An object used to pass state from one promise to the next
     * @param continueAfterFailure If true, queues the next promise (after logging an error), even if the current one fails
     */
    public Chain(List<Promise> promises, Object passThrough, Boolean continueAfterFailure) {
        this.promises = promises;
        this.passThrough = passThrough;
        this.continueAfterFailure = continueAfterFailure;
    }

    /**
     * @description Queues the next promise in the chain, unless the current queueable failed and continueAfterFailure
     * is false
     * @param context FinalizerContext
     */
    public void execute(FinalizerContext context) {
        Id parentQueueableJobId = context.getAsyncApexJobId();
        switch on context.getResult() {
            when SUCCESS {
                queueNext();
            }
            when UNHANDLED_EXCEPTION {
                handleFailedQueueableJob(parentQueueableJobId, context.getException()?.getMessage());
            }
        }
    }

    @TestVisible
    private void handleFailedQueueableJob(Id parentQueueableJobId, String contextExceptionMessage) {
        String errorMessage = 'Parent Queueable (Job ID: ' + parentQueueableJobId + '): failed' + '\n' +
            'Parent Queueable Exception: ' + contextExceptionMessage;
        if (continueAfterFailure) {
            errorMessage += '\n' + 'Continuing to execute ' + this.promises.size() + ' other promises';
            queueNext();
        } else {
            errorMessage += '\n' + 'Not executing ' + this.promises.size() + ' other promises';
        }
        Logger.logNow('Chain', 'execute', errorMessage, Logger.ERROR);
    }

    private void queueNext() {
        if (this.promises == null || this.promises.isEmpty()) {
            return;
        }
        Promise next = this.promises.remove(0);
        next.promises = this.promises;
        next.passThrough = this.passThrough;
        if (callQueueableChain) {
            System.enqueueJob(next);
        } else {
            nextPromise = next;
        }
    }
}