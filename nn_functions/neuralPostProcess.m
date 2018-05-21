function output = neuralPostProcess(input, layer)

switch(lower(layer.output.type))
    case 'lhthresh'
        input(input > layer.output.threshold.high) = layer.output.threshold.high;
        input(input < layer.output.threshold.low) = layer.output.threshold.low;
    otherwise
        error('unrecognized post processing funciton')       
end
    output = input;

end
