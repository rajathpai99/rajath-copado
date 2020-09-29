public class TemperatureConverter {
    // Takes a Fahrenheit temperature and returns the Celsius equivalent.
    public static Decimal fhToCelsius(Decimal fh) {
        Decimal cels = (fh - 32) * 5/9;
        System.debug('Copado Rocks - updated!!!');
        System.debug('Additional Line - updated - v2 version!!');
        return cels.setScale(2);
        //Additional comment overwrite v1
        //One more comment
    }

}