/**
 * @description Promise implementation in apex, per:
 * https://developer.salesforce.com/blogs/2020/01/learn-moar-in-spring-20-implementing-promises-with-transaction-finalizers.html
 * Tested By: PromniseTest
*/
public abstract class Promise implements Queueable, Database.AllowsCallouts {
    public List<Promise> promises = new List<Promise>();
    public Object passThrough;
    public Boolean continueChainAfterFailure = true;
    protected Chain chain;

    public Promise then(Object toAdd) {
        promises.add((Promise) toAdd);
        return this;
    }

    abstract public void execute();

    public virtual void execute(QueueableContext context) {
        chain = new Chain(this.promises, this.passThrough, this.continueChainAfterFailure);
        System.attachFinalizer(chain);
        execute();
    }
}