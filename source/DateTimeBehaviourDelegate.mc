using Toybox.WatchUi as Ui;
using Toybox.Background;

class DateTimeBehaviourDelegate extends Ui.BehaviorDelegate {


    function initialize() {
      BehaviorDelegate.initialize();
    }

    function onTap(evt) {
      GlobalTouched = 1;
      return true;    
    }

}